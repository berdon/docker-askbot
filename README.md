# docker-askbot
Docker for askbot supporting volume for persisted data, easily overridable settings, and custom python support

- Uses a /data docker volume for settings overriding and storing a sqlite data file
- Can easily customize install by overriding settings

## Quick Start

```bash
# Use jwilder/nginx-proxy for nginx
docker run -d -p 8080:80 --name nginx-proxy -p 4443:443 -v /var/run/docker.sock:/tmp/docker.sock -v /askbot/nginx/certs:/etc/nginx/certs -v /askbot/nginx/vhost.d:/etc/nginx/vhost.d -v /askbot/nginx/html:/usr/share/nginx/html -t jwilder/nginx-proxy

# Launch askbot
docker run -e VIRTUAL_HOST=www.my-sweet-askbot-site.com -v /askbot:/data/ -d berdon/docker-askbot:latest
```

## Customing Askbot

Askbot relies heavily on `settings.py` for settings. You can override these settings in your /data volumes `/data/override/settingsoverride.py` file. This gets loaded at runtime and anything specified overrides the values in the default file.

## Examples

### I want to use PostgreSQL!

Askbot uses Django so this is mostly just updating Django to use PostgreSQL.

Modify your /data volume's `/data/override/settingsoverride.py` with something like:

```py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'DATABASE',
        'USER': 'USER',
        'PASSWORD': 'PASSWORD',
        'HOST': 'HOST',
        'PORT': 'PORT',
    }
}
```

### How on earth do I get LDAP / Active Directory to work?

You may or may not have a lot of issues getting LDAP to work. Askbot themselves gives the guidance of "set up a debugger" and step through it. Ultimately, that's probably what you'll need to do.

Depending on your LDAP / AD settings, you may or may not need to have a master username or password. Security wise, that sucks since in many organizations it's brutally hard to get access to a user specifically meant to authenticate against an LDAP server just to then authenticate another user.

It _may_ be worth your time to add a custom LDAP authentication function mirror Askbot's that treats the `LDAP_LOGIN_DN` and `LDAP_PASSWORD` settings as string templates like:

```python
#add optional "master" LDAP authentication, if required
master_username = getattr(django_settings, 'LDAP_LOGIN_DN', None) % (username)
master_password = getattr(django_settings, 'LDAP_PASSWORD', None) % (password)
```

See the original `ldap_authenticate_default` method in `askbot/deps/django_authopenid` to create your own function. Then include that function in the /data volume's `/data/contrib/` and set your custom authentication function by overriding the `LDAP_AUTHENTICATE_FUNCTION` setting in `/data/override/settingsoverride.py`. As an example, if you have `/data/contrib/my_ldap_module.py` with your own version of `ldap_authenticate_default` then you would add the following to your setting override file:

```python
LDAP_AUTHENTICATE_FUNCTION='my_ldap_module.ldap_authenticate_default'
```

### How do I see useful logs?

Try adding the below to your /data volume's `/data/override/settingsoverride.py` to get Askbot logs. Additionally, you can look in `/data/logs/` for USWGI logs.

```python
import logging
logging.basicConfig(
    filename='/data/logs/askbot.log',
    level=logging.DEBUG,
    format='%(pathname)s TIME: %(asctime)s MSG: %(filename)s:%(funcName)s:%(lineno)d %(message)s',
)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'class': 'logging.FileHandler',
            'filename': '/data/logs/askbot.log',
        },
    },
    'root': {
        'handlers': ['file'],
        'level': 'INFO',
    },
}
```