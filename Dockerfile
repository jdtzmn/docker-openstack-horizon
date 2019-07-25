FROM ubuntu:18.04

ENV HORIZON_BASEDIR=/etc/horizon \
    OPENSTACK_HOST='keystone' \
    KEYSTONE_URL='\"http://%s:5000/v3" % OPENSTACK_HOST' \
    TOX_TESTENV_PASSENV='KEYSTONE_HOST KEYSTONE_URL' \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    LANG=C \
    VERSION=master


EXPOSE 80

# Install dependencies
RUN \
  apt-get update && \
  apt-get install -y \
    memcached git python-pip python3 gettext \
    python3-dev python3-distutils && \
  git clone --branch $VERSION --depth 1 https://opendev.org/openstack/horizon.git ${HORIZON_BASEDIR} && \
  cd ${HORIZON_BASEDIR} && \
  pip install tox

# Setup local_settings.py
RUN \
  cd ${HORIZON_BASEDIR} && \
  cp openstack_dashboard/local/local_settings.py.example openstack_dashboard/local/local_settings.py && \
  sed -i 's/^DEBUG.*/DEBUG = True/g' $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  echo 'COMPRESS_ENABLED = False' >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  sed -i 's/^OPENSTACK_HOST.*/OPENSTACK_HOST = os\.getenv("OPENSTACK_HOST")/g' \
    $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  sed -i 's/^OPENSTACK_KEYSTONE_URL.*/OPENSTACK_KEYSTONE_URL = os\.getenv("KEYSTONE_URL")/g' \
    $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  printf  "\nALLOWED_HOSTS = ['*', ]\n" >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" \
    >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  echo 'OPENSTACK_API_VERSIONS = {"identity": os.getenv("IDENTITY_API_VERSION", 3) }' \
    >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  echo 'OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"' \
    >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  echo 'OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"' \
    >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py && \
  printf "\
CACHES = {\n\
    'default': {\n\
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',\n\
        'LOCATION': 'localhost:11211',\n\
    },\n\
}\n"\
    >> $HORIZON_BASEDIR/openstack_dashboard/local/local_settings.py

# Setup tox
RUN \
  cd $HORIZON_BASEDIR && \
  tox install -e runserver --notest

COPY start.sh /start.sh

CMD sh -x /start.sh
