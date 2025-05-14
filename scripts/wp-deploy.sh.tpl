#!/bin/bash

apt-get update
apt-get install -y apache2 php php-mysql php-redis libapache2-mod-php mysql-client unzip curl

wget https://wordpress.org/latest.zip
unzip latest.zip
cp -r wordpress/* /var/www/html/

cat <<EOF > /var/www/html/wp-config.php
<?php
define('DB_NAME', getenv('DB_NAME'));
define('DB_USER', getenv('DB_USER'));
define('DB_PASSWORD', getenv('DB_PASSWORD'));
define('DB_HOST', getenv('DB_HOST'));
define('WP_REDIS_HOST', getenv('WP_REDIS_HOST'));
define('WP_REDIS_PORT', getenv('WP_REDIS_PORT'));
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if (!defined('ABSPATH')) define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
EOF

cat <<EOF >> /etc/environment
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_pass}
DB_HOST=${db_host}
WP_REDIS_HOST=${redis_host}
WP_REDIS_PORT=6379
EOF

chown -R www-data:www-data /var/www/html
systemctl restart apache2
