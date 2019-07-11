# Start the services
service memcached start
cd $HORIZON_BASEDIR
git init
export TOX_TESTENV_PASSENV=KEYSTONE_HOST
tox -e runserver -- 0.0.0.0:80
