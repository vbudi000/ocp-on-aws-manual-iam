# Working on OpenShift on AWS with Manual Credential

## Prerequisites

- openshift-install command
- oc command
- aws command
- jq command
- yq command

## Creation Procedure

1. Prepare your install-config template:

    ``` bash
    openshift-install create install-config
    echo "credentialsMode: Manual" >> install-config.yaml
    cp install-config.yaml install-config.template
    ```

2. Prepare connection to AWS:

    ``` bash
    export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXX"
    export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXX"
    export AWS_SESSION_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    export AWS_DEFAULT_REGION="us-east-1"
    ```

3. Create the cluster with manual credentials:

    ``` bash
    export OUTPUT_DIR=<cluster dir> ./credreq.sh
    ```

## Removal Procedure

1. Deleting Cluster

    ``` bash
    openshift-install destroy cluster --dir=<cluster dir>
    ```

2. Cleaning up resources

    ```bash
    export OUTPUT_DIR=<cluster dir> ./creddel.sh
    ```