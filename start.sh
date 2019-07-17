# Start the services
service memcached start
cd $HORIZON_BASEDIR
git init
tox -e runserver -- 0.0.0.0:80
