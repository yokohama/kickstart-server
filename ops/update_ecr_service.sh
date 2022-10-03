#!/bin/bash

if [ "${TARGET_ENV}" = "" ]; then
  echo '[Error]'
  echo '- TARGET_ENV param required. [ local | dev | prod ]'
  echo '- ex) TARGET_ENV=local ./init/ecr_init_push.sh'
  exit 1
fi

CLUSTER_ARN=`aws ecs list-clusters | jq -r '.clusterArns[]' | grep ${TARGET_ENV}`
if [ "${CLUSTER_ARN}" = "" ]; then
  echo '[Error]'
  echo '- Cluster dose not exist'
  exit 1
fi

SERVICE_ARN=`aws ecs list-services --cluster ${CLUSTER_ARN} | jq -r '.serviceArns[]' | grep ${TARGET_ENV}`
if [ "${SERVICE_ARN}" = "" ]; then
  echo '[Error]'
  echo '- Service dose not exist'
  exit 1
fi

TASK_DEFINITION_NAME=`aws ecs list-task-definitions | jq -r '.taskDefinitionArns[]' | grep ${TARGET_ENV}`
echo $TASK_DEFINITION_NAME
if [ "${TASK_DEFINITION_NAME}" = "" ]; then
  echo '[Error]'
  echo '- TaskDefinition dose not exist'
  exit 1
fi

aws ecs update-service --cluster ${CLUSTER_ARN} --service ${SERVICE_ARN} --task-definition ${TASK_DEFINITION_NAME} --force-new-deployment 1>/dev/null
