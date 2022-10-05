#!/bin/sh
set -e

rm -f /opt/app/tmp/pids/server.pid
#rake db:migrate

exec "$@"
