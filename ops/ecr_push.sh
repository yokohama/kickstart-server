#!/bin/bash
#
# 事前に、.evnファイルに、
# AWS_REGIONとAWS_ACCOUNT_IDを記入しておく。
#

# ISSUE: 6

if [ "${TARGET_ENV}" = "" ]; then
  echo '[Error]'
  echo '- TARGET_ENV param required. [ local | dev | prod ]'
  echo '- ex) TARGET_ENV=local ./init/ecr_init_push.sh'
  exit 1
fi
REPO_NAME=ecr-${TARGET_ENV}

AWS_REGION=`cat .env.development | grep AWS_REGION | awk -F'[=]' '{print $2}'`
AWS_ACCOUNT_ID=`cat .env.development | grep AWS_ACCOUNT_ID | awk -F'[=]' '{print $2}'`
if [ "${AWS_REGION}" = "" ] || [ "${AWS_ACCOUNT_ID}" = "" ]; then
  echo '[Error]'
  echo '- aws_resion or asw_account_id settings not found.'
  echo '- Please check your .evn file.'
  exit 1
fi

IMAGE_ID=`docker images | grep kickstart | awk '{print $3}'`
if [ "${IMAGE_ID}" = "" ]; then
  echo '[Error]'
  echo '- docker image not found.'
  echo '- Please check docker images. Does kickstart image exist?'
  exit 1
fi

# ECRに対してDockerクライアント認証をする。
aws ecr get-login-password --region ${AWS_REGION} | 
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# リポジトリのURIを取得
REPO_URI=`aws ecr describe-repositories | 
  jq -r '.repositories[].repositoryUri' | 
  grep ${REPO_NAME}`

if [ "${REPO_URI}" = "" ]; then
  echo '[Error]'
  echo '- ECR repository does not exist.'
  echo "- Please make sure that your repository has ${REPO_NAME}"
  exit 1
fi

# build & タグ付け
DOCKER_BUILDKIT=1 docker build . -t ${REPO_URI}:latest

# イメージをERCRにpush
docker push ${REPO_URI}:latest
