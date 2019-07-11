# Configure Apache2
echo "ServerName $HOSTNAME" >> /etc/apache2/apache2.conf

# Start the services
service memcached start
/usr/sbin/apache2 -DFOREGROUND