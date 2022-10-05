#!/bin/bash

echo ${AWS_REGION}
echo ${AWS_ACCOUNT_ID}
echo ${FIREBASE_PROJECT_ID}
echo ${DELETE_ONLY}

if [ "${AWS_REGION}" = "" ] || [ "$AWS_ACCOUNT_ID" = "" ] || [ "$FIREBASE_PROJECT_ID" = "" ]; then
  echo '[Error]'
  echo '- ex) AWS_REGION=ap-northeast-1 AWS_ACCOUNT_ID=400000000 FIREBASE_PROJECT_ID=hgoehoge-0000 ./ops/renew.sh'
  exit 1
fi

#
# localのコンテナやイメージ、ファイルを初期化
#
docker compose down

delete_files=(
  app 
  bin
  config*
  db
  Gemfile*
  lib
  log
  public
  Rakefile
  .ruby-version
  storage
  tmp
  vendor
  test
  .env*
)
for i in ${delete_files[@]}; do sudo rm -rf $i; done

docker ps -a | awk '{print $1}' | xargs docker rm 
docker images | awk '{print $3}' | xargs docker rmi -f
docker volume ls | awk '{print $2}' | xargs docker volume rm
docker container ls -a | awk '{print $1}' | grep -v 'CONTAINER' | xargs docker container rm

docker ps -a
docker images
docker volume ls
docker container ls -a

if [ "${DELETE_ONLY}" = "true" ]; then
  exit 0
fi

#
# aws上の不要なファイル削除
#
# まだ運用がわからないのでコメント
# aws cloud watch log groups削除
#LOG_GROUPS=($(aws logs describe-log-groups | jq -r '.logGroups[].logGroupName' | grep "\-${TARGET_ENV}"))
#for i in ${LOG_GROUPS[@]}; do
#  aws logs delete-log-group --log-group-name $i
#done


#
# 初期化
#
make new
git checkout origin/development -- README.md

sed -i "s/AWS_REGION=/AWS_REGION=${AWS_REGION}/g" .env.development
sed -i "s/AWS_ACCOUNT_ID=/AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}/g" .env.development
sed -i "s/FIREBASE_PROJECT_ID=/FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}/g" .env.development

envs=(local dev prod)
for i in ${envs[@]}; do
  echo "##"
  echo "## ${i} ECR push"
  echo "##"
  TARGET_ENV=$i ops/ecr_push.sh

  echo "##"
  echo "## ${i} fargate Service update"
  echo "##"
  TARGET_ENV=$i ops/update_ecr_service.sh 1>/dev/null

  echo "##"
  echo "## ${i} rails db:migrate:reset"
  echo "##"
  TARGET_ENV=$i ops/rails_task.sh db:migrate:reset 1>/dev/null

  if [ "${i}" = "local" ]; then
    echo "##"
    echo "## ${i} rails db:migrate"
    echo "##"
    TARGET_ENV=$i ops/rails_task.sh db:migrate 1>/dev/null
  fi
done

echo "##"
echo "## prod regist master.key"
echo "##"
./ops/regist_rails_master_key.sh 1>/dev/null
