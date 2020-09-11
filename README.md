# aspera-hsts-operator-tools
IBM Aspera HSTS Operator support tools


## support_bundle.sh

Generate IBM Aspera HSTS Operator / Operand support bundle.

### Requirements:

* oc (OpenShift Client)
* xargs
* tar

### Usage:

1. Open `support_bundle.sh` and change the `NAMESPACE` and `CR_NAME` to match your `IBMAsperaHSTS` custom resouce.

    ```bash
    export OC_BIN=oc
    export NAMESPACE=hsts
    export CR_NAME=quickstart
    ```
2. Optionally update the `OC_BIN` to the path to your `oc` or `kubectl` binary if not available via `PATH`.
3. Run the script `./support_bundle.sh`
4. Upload the `crname_support_bundle_timestamp.tar.gz` file via ECuRep or other appropriate method.
