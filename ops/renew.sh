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
#for i in ${delete_files[@]}; do
#  aws logs delete-log-group --log-group-name $i
#done

#
# 初期化
#
make new

TARGET_ENV=local ops/ecr_push.sh
TARGET_ENV=local ops/update_ecr_service.sh
TARGET_ENV=local ops/rails_db_migrate.sh
