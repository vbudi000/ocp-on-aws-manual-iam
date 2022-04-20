#! /usr/bin/env bash

if [ -z ${OUTPUT_DIR} ]; then
  OUTPUT_DIR="."
fi

INFRA_ID=$(cat ${OUTPUT_DIR}/manifests.orig/cluster-infrastructure-02-config.yml | grep infrastructureName | cut -d":" -f2)

clusterId=$INFRA_ID
# Delete users
if [ -z ${clusterId} ]; then 
  echo "Cannot find Infrastructure ID - exiting ..."
  exit 99
fi

echo "Running cleanup for ${OUTPUT_DIR}"

for user in $(aws iam list-users | grep UserName | grep ${clusterId} | cut -d\" -f 4); do
  akid=$(aws iam list-access-keys --user-name ${user} | grep AccessKeyId | cut -d\" -f 4)
  echo "Deleting ${user}"
  aws iam delete-access-key --user-name ${user} --access-key-id ${akid}
  aws iam delete-user --user-name ${user}
done

for policy in $(aws iam list-policies | grep Arn | grep ${clusterId} | cut -d\" -f4); do 
  echo "Deleting ${policy}"
  aws iam delete-policy --policy-arn ${policy}
done

echo "Deleting files"

rm "install-config.yaml.orig"
rm -rf manifests.orig
rm -rf openshift.orig

exit