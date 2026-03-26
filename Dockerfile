FROM php:8.2-apache-bookworm

ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV PHP_INI_MEMORY_LIMIT=256M
ENV PHP_INI_UPLOAD_MAX_FILESIZE=20M
ENV PHP_INI_POST_MAX_SIZE=25M
ENV PHP_INI_ALLOW_URL_FOPEN=0

RUN apt-get update -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libc-client-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libldap2-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        default-mysql-client \
        cron \
    && apt-get autoremove -y \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) calendar intl mysqli pdo_mysql gd soap zip \
    && docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy application code
COPY dolibarr/htdocs /var/www/html/

# Create documents directory
RUN mkdir -p /var/www/documents \
    && chown -R www-data:www-data /var/www/html /var/www/documents \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
