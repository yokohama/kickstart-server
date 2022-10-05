#!/bin/bash

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

envs=(local dev prod)
for i in ${envs[@]}; do
  TARGET_ENV=$i ops/ecr_push.sh
  TARGET_ENV=$i ops/update_ecr_service.sh
  TARGET_ENV=$i ops/rails_task.sh db:migrate:reset
  TARGET_ENV=$i ops/rails_task.sh db:migrate
done
