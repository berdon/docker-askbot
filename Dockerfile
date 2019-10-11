FROM ubuntu:16.04 

LABEL maintainer="Austin Hanson <berdon@gmail.com>"

RUN apt-get update && apt-get -y upgrade && apt-get install python-pip libsasl2-dev python-dev libldap2-dev libssl-dev -y

VOLUME ["/data"]

# Install askbot
RUN pip install askbot

# Setup askbot (defaults to using sqlite)
RUN askbot-setup -n /app -e 2 -d /data/askbot.db

# Disable debug mode (see readme on enabling)
RUN sed -i "s|^DEBUG = True|DEBUG = False|" /app/settings.py

# Some garbage handling because askbot maybe doesn't pin dependency versions?
RUN pip install -U --force-reinstall six==1.10.0
RUN pip install uWSGI==2.0.11 wsgiref==0.1.2

# Necessary for the optional LDAP support (which I'm dictating as being required functionally optional)
RUN pip install python-ldap

WORKDIR /app

# Append some stuff to add to python's import path and allow for settings overriding
COPY ./conf/settings-override.py /app/settings-override.py
RUN cat /app/settings-override.py >> /app/settings.py
RUN rm /app/settings-override.py

# Copy over some runtime stuff
COPY ./conf/uwsgi.ini /app/uwsgi.ini
COPY ./conf/run.sh /app/post-deploy.sh
RUN chmod +x /app/post-deploy.sh

EXPOSE 80
CMD ["/app/post-deploy.sh"]