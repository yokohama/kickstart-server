#!/bin/sh

MASTER_KEY=`cat config/master.key`
aws secretsmanager update-secret --secret-id rails-master-key-prod --secret-string {\"railsMasterKey\":\"${MASTER_KEY}\"}
