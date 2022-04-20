#! /usr/bin/env bash

if [ -z ${OUTPUT_DIR} ]; then
  OUTPUT_DIR="."
fi

[ ! -d "${OUTPUT_DIR}" ] && mkdir ${OUTPUT_DIR}

echo "Collecting credential request objects based on your openshift-install command"

REL_IMAGE=$(openshift-install version | grep "release image" | cut -d" " -f3 )
pushd ${OUTPUT_DIR}
oc adm release extract ${REL_IMAGE} --credentials-requests --cloud=aws --dir=${OUTPUT_DIR}
popd

echo "Creating manifest from install-config.yaml template"
cp install-config.template ${OUTPUT_DIR}/install-config.yaml

openshift-install create manifests --dir=${OUTPUT_DIR}

INFRA_ID=$(cat ${OUTPUT_DIR}/manifests/cluster-infrastructure-02-config.yml | grep infrastructureName | cut -d":" -f2)

for creq in $(ls ${OUTPUT_DIR}/00*.yaml); do
  OBJNAME=$(cat ${creq} | yq '.metadata.name')
  SECRETNAME=$(cat ${creq} | yq '.spec.secretRef.name')
  SECRETNS=$(cat ${creq} | yq '.spec.secretRef.namespace')
  CREDPOL=$(cat ${creq} | yq '.spec.providerSpec.statementEntries' -o json | sed 's/"action"/"Action"/g;s/"effect"/"Effect"/g;s/"resource"/"Resource"/g;s/"policyCondition"/"Condition"/g')
  echo "{\"Version\": \"2012-10-17\"}" | jq --argjson STATEMT "${CREDPOL}" '. + {"Statement": $STATEMT}' > ${OUTPUT_DIR}/${OBJNAME}.json
  polArn=$(aws iam create-policy --policy-name ${INFRA_ID}-${OBJNAME} --policy-document file://${OUTPUT_DIR}/${OBJNAME}.json | grep Arn | cut -d\" -f4)
  iamUser=$(aws iam create-user --user-name ${INFRA_ID}-${OBJNAME})
  attUsr=$(aws iam attach-user-policy --user-name ${INFRA_ID}-${OBJNAME} --policy-arn ${polArn})
  iamKey=$(aws iam create-access-key --user-name ${INFRA_ID}-${OBJNAME})
  ACCESS=$(echo "${iamKey}" | jq -r '.AccessKey.AccessKeyId')
  SECRET=$(echo "${iamKey}" | jq -r '.AccessKey.SecretAccessKey')
  cat secret.template | sed "s/SECRET_NAME/${SECRETNAME}/g;s/SECRET_NS/${SECRETNS}/g;s/ACCESSKEY/${ACCESS}/g;s#ACCESSSECRET#${SECRET}#g" > ${OUTPUT_DIR}/manifests/${OBJNAME}-secret.yaml
  rm ${creq}
  rm ${OUTPUT_DIR}/${OBJNAME}.json
done

cp -R ${OUTPUT_DIR}/manifests ${OUTPUT_DIR}/manifests.orig
cp -R ${OUTPUT_DIR}/openshift ${OUTPUT_DIR}/openshift.orig

openshift-install create cluster --dir=${OUTPUT_DIR}

exit