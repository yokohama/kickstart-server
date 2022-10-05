#!/bin/sh

MASTER_KEY=`cat config/master.key`
echo $MASTER_KEY
#aws secretsmanager update-secret --secret-id rails-master-key-prod --secret-string ${MASTER_KEY}
