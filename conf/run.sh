#!/bin/bash

cd /app

if [ ! -d /data/contrib ]; then
  mkdir /data/contrib;
fi

if [ ! -d /data/logs ]; then
  mkdir /data/logs;
fi

if [ ! -d /data/nginx ]; then
  mkdir /data/nginx;
  mkdir /data/nginx/certs;
  mkdir /data/nginx/html;
  mkdir /data/vhost.d;
fi

if [ ! -d /data/override ]; then
  mkdir /data/override;
  touch /data/override/settingsoverride.py;
fi

python manage.py collectstatic --noinput
python manage.py syncdb --noinput
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# Run via debugging server
exec /usr/local/bin/uwsgi /app/uwsgi.ini