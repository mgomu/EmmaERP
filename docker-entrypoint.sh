#!/bin/bash
# Railway-adapted entrypoint for EmmaERP (Dolibarr)

# Railway provides PORT env var — configure Apache to listen on it
if [ -n "$PORT" ]; then
    echo "[entrypoint] Configuring Apache to listen on port $PORT"
    sed -i "s/Listen 80/Listen $PORT/" /etc/apache2/ports.conf
    sed -i "s/:80/:$PORT/" /etc/apache2/sites-available/000-default.conf
fi

# PHP configuration
echo "[entrypoint] Writing PHP config"
cat <<EOF > "${PHP_INI_DIR}/conf.d/dolibarr-php.ini"
date.timezone = ${PHP_INI_DATE_TIMEZONE:-UTC}
memory_limit = ${PHP_INI_MEMORY_LIMIT:-256M}
upload_max_filesize = ${PHP_INI_UPLOAD_MAX_FILESIZE:-20M}
post_max_size = ${PHP_INI_POST_MAX_SIZE:-25M}
allow_url_fopen = ${PHP_INI_ALLOW_URL_FOPEN:-0}
EOF

# Ensure documents directory exists and has correct permissions
mkdir -p /var/www/documents
chown -R www-data:www-data /var/www/documents
chown -R www-data:www-data /var/www/html/conf

# Generate install.forced.php from environment variables
echo "[entrypoint] Generating install.forced.php"
cat <<'PHPEOF' > /var/www/html/install/install.forced.php
<?php
$force_install_distrib = 'custom';
$force_install_nophpinfo = true;
$force_install_noedit = 2;
$force_install_message = 'EmmaERP - Powered by Dolibarr';
$force_install_main_data_root = '/var/www/documents';
$force_install_mainforcehttps = true;
$force_install_type = 'mysqli';
$force_install_dbserver = getenv('MYSQLHOST') ?: getenv('DOLI_DB_SERVER') ?: 'localhost';
$force_install_port = getenv('MYSQLPORT') ?: getenv('DOLI_DB_PORT') ?: '3306';
$force_install_database = getenv('MYSQLDATABASE') ?: getenv('DOLI_DATABASE') ?: 'dolibarr';
$force_install_prefix = 'llx_';
$force_install_createdatabase = false;
$force_install_databaselogin = getenv('MYSQLUSER') ?: getenv('DOLI_DB_USER') ?: 'root';
$force_install_databasepass = getenv('MYSQLPASSWORD') ?: getenv('DOLI_DB_PASSWORD') ?: '';
$force_install_createuser = false;
$force_install_dolibarrlogin = 'admin';
$force_install_dolibarrpassword = '';
$force_install_databaserootlogin = getenv('MYSQLUSER') ?: getenv('DOLI_DB_USER') ?: 'root';
$force_install_databaserootpass = getenv('MYSQLPASSWORD') ?: getenv('DOLI_DB_PASSWORD') ?: '';
$force_install_lockinstall = true;
PHPEOF

echo "[entrypoint] Starting Apache..."
exec "$@"
