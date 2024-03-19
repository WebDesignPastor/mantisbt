# Use the official PHP image with Apache
FROM php:7.4-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libldap2-dev \
    libldb-dev \
    mariadb-client \
    git \
    unzip \
    # Add this line to install libzip-dev
    libzip-dev \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip


# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Allow Composer to run as super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Use WORKDIR to specify the working directory
WORKDIR /var/www/html

# Download and install MantisBT
ARG MANTIS_VERSION=2.24.4
RUN curl -o mantisbt.tar.gz -L "https://github.com/mantisbt/mantisbt/archive/release-${MANTIS_VERSION}.tar.gz" \
    && tar -xf mantisbt.tar.gz -C /var/www/html --strip-components=1 \
    && rm mantisbt.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Install MantisBT dependencies with Composer
RUN composer install --no-dev --optimize-autoloader

# Configure PHP
RUN { \
    echo 'file_uploads = On'; \
    echo 'memory_limit = 256M'; \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'max_execution_time = 600'; \
} > /usr/local/etc/php/conf.d/mantis.ini

# Expose port 80
EXPOSE 80

# Copy entrypoint script to the image
COPY docker-entrypoint.sh /usr/local/bin/

# Give execution rights on the entrypoint script
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set the entrypoint to initialize the database
ENTRYPOINT ["docker-entrypoint.sh"]

# Start Apache
CMD ["apache2-foreground"]
