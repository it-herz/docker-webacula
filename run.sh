#!/bin/bash

NOTCONNECTED=1
while [ $NOTCONNECTED == 1 ]
do
  echo Waiting for database
  sleep 3
  nc -z $PG_HOST $PG_PORT
  NOTCONNECTED=$?
done

export PGPASSWORD=$PG_PWD
NOTPRESENT=1
while [ $NOTPRESENT == 1 ]
do
  psql -lqt -h $PG_HOST -U $PG_USER | cut -d \| -f 1 | grep -qw $PG_DB
  NOTPRESENT=$?
done

# workaround for php7.0 socket
mkdir -p /run/php

if [ ! -f /initialized ]
then
  sed -i "s/DIR_NAME/$DIR_NAME/g" /opt/bacula/etc/bconsole.conf
  sed -i "s/DIR_HOST/$DIR_HOST/g" /opt/bacula/etc/bconsole.conf
  sed -i "s/DIR_PWD/$DIR_PWD/g" /opt/bacula/etc/bconsole.conf
  sed -i "s/DIR_NAME/$DIR_NAME/g" /opt/bacula/etc/bconsole.conf

  sed -i "s/PG_HOST/$PG_HOST/g" /usr/share/webacula/application/config.ini
  sed -i "s/PG_DB/$PG_DB/g" /usr/share/webacula/application/config.ini
  sed -i "s/PG_USER/$PG_USER/g" /usr/share/webacula/application/config.ini
  sed -i "s/PG_PWD/$PG_PWD/g" /usr/share/webacula/application/config.ini
  sed -i "s/DOMAIN/$DOMAIN/g" /usr/share/webacula/application/config.ini

  sed -i "s/PG_PWD/$PG_PWD/g" /usr/share/webacula/install/db.conf

  ln -s /usr/share/timezone/$TIMEZONE /etc/localtime && dpkg-reconfigure tzdata

  pushd /usr/share/webacula/install/
  RP=`php password-to-hash.php $ROOT_PWD`
  popd
  sed -i "s~ROOT_PWD~$RP~g" /usr/share/webacula/install/db.conf

  sed -i 's/NOW().-.StartTime/NOW() - j.StartTime/g' /usr/share/webacula/application/models/Job.php
  sed -i "s/'BACULA_VERSION', 14/'BACULA_VERSION', 15/ig" /usr/share/webacula/html/index.php

  cd /usr/share/webacula/install/PostgreSql
  echo "SELECT table_name FROM information_schema.tables WHERE table_schema='public'" | psql -q -h $PG_HOST -U $PG_USER -f - -d $PG_DB | grep webacula_users
  if [ $? -ne 0 ]
  then
    # если таблица webacula_users не существует - заполнить БД
    ./10_make_tables.sh
    ./20_acl_make_tables.sh
  fi

  chmod u+s /opt/bacula/bin/bconsole
  touch /initialized
fi
