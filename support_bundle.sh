#!/bin/bash

export OC_BIN=oc
export NAMESPACE=hsts
export CR_NAME=quickstart


function pod_containers {
    $OC_BIN get pod -n "$NAMESPACE" "$1" --no-headers -o=jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}'
}
export -f pod_containers

function pod_logs {
    for c in $(pod_containers $1); do
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< $1/$c START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        $OC_BIN logs -n "$NAMESPACE" "$1" -c "$c"
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $1/$c END >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    done
}
export -f pod_logs

function hsts_operator_pods {
    $OC_BIN get pod --all-namespaces -l name=ibm-aspera-hsts-operator \
        -o=jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}'
}

function get_pod_names {
    $OC_BIN get pod -n "$NAMESPACE" -o='jsonpath={range .items[*]}{.metadata.name}{"\n"}{end}' -l "cr.name=$CR_NAME" "$@"
}

function operand_config {
    $OC_BIN get ibmasperahsts -n "$NAMESPACE" $CR_NAME -o yaml
    $OC_BIN get redissentinel -n "$NAMESPACE" -l "cr.name=$CR_NAME" -o yaml
    $OC_BIN get configmap -n "$NAMESPACE" -l "cr.name=$CR_NAME" -o yaml
}

function ibmasperahsts_pvcs {
    $OC_BIN get ibmasperahsts -n "$NAMESPACE" $CR_NAME --no-headers -o=jsonpath='{range .spec.storage[*]}{.claimName}{"\n"}{end}'
}

function pvc_yaml {
    for pvc in $(ibmasperahsts_pvcs); do
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< $CR_NAME/$pvc START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        $OC_BIN get pvc -n "$NAMESPACE" $pvc -o yaml
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $CR_NAME/$pvc END >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    done
}

function ibmasperahsts_pods {
    $OC_BIN get pod -n "$NAMESPACE" -l "app.kubernetes.io/managed-by=ibm-aspera-hsts,cr.name=$CR_NAME" \
        -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
    $OC_BIN get pod -n "$NAMESPACE" -l "formation_id=$CR_NAME-redis,formation_type=redis" \
        -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
}

function pod_yaml {
    for pod in $(ibmasperahsts_pods); do
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< $CR_NAME/$pod START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        $OC_BIN get pod -n "$NAMESPACE" $pod -o yaml
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $CR_NAME/$pod END >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    done
}

function main {
    mkdir -p hsts_support_bundle
    cd hsts_support_bundle

    operand_config > operand_config.txt
    pvc_yaml > pvc_yaml.txt
    pod_yaml > pods_yaml.txt
    hsts_operator_pods                             | xargs -t -n2 $OC_BIN logs -n > hsts-operator.log 2>&1
    get_pod_names -l "name=ascp"                   | xargs -I% bash -c "pod_logs %" > ascp.log
    get_pod_names -l "name=asperanoded"            | xargs -I% bash -c "pod_logs %" > asperanoded.log
    get_pod_names -l "name=asperanoded-master"     | xargs -I% bash -c "pod_logs %" > asperanoded-master.log
    get_pod_names -l "name=engine"                 | xargs -I% bash -c "pod_logs %" > engine.log
    get_pod_names -l "name=http-proxy"             | xargs -I% bash -c "pod_logs %" > http-proxy.log
    get_pod_names -l "name=http-scheduler"         | xargs -I% bash -c "pod_logs %" > http-scheduler.log
    get_pod_names -l "name=prometheus"             | xargs -I% bash -c "pod_logs %" > prometheus.log
    get_pod_names -l "name=tcp-proxy"              | xargs -I% bash -c "pod_logs %" > tcp-proxy.log
    get_pod_names -l "name=tcp-scheduler"          | xargs -I% bash -c "pod_logs %"  > tcp-scheduler.log
    get_pod_names -l "formation_type=redis,role=m" | xargs -I% bash -c "pod_logs %" > redis-m.log
    get_pod_names -l "formation_type=redis,role=s" | xargs -I% bash -c "pod_logs %" > redis-s.log

    cd ..
    tar -czvf "${CR_NAME}_support_bundle_$(date +"%FT%H%M%S").tar.gz" hsts_support_bundle
}

main "$@"