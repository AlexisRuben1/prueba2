# Partimos de la imagen php en su versión 7.4
FROM php:8.0-fpm-alpine

# Copiamos los archivos package.json composer.json y composer-lock.json a /var/www/
COPY composer*.json /var/www/

# Nos movemos a /var/www/
WORKDIR /var/www/

# Instalamos las dependencias necesarias
RUN apt-get update && apt-get install -y \
    build-essential \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    git \
    curl

# Instalamos extensiones de PHP
RUN docker-php-ext-install pdo_mysql zip exif pcntl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd mbstring

# Instalamos composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalamos dependencias de composer
RUN composer install --no-ansi --no-dev --no-interaction --no-progress --optimize-autoloader --no-scripts

# Configuración adicional de extensiones de PHP
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl soap

# Configuración de Composer
FROM composer AS composer_stage
COPY --from=latest /usr/bin/composer /usr/bin/composer
USER www-data
WORKDIR /var/www/html/
COPY --chown=www-data:www-data composer.lock composer.json /var/www/html/
RUN composer install --no-interaction --no-dev --no-autoloader

# Configuración final del contenedor
FROM php AS app
ENV COMPOSER_MEMORY_LIMIT=-1 \
    LOG_CHANNEL=stderr \
    APP_LOG=errorlog \
    APP_LOG_LEVEL=info

USER root

# Copiamos todos los archivos de la carpeta actual de nuestra 
# computadora (los archivos de Laravel) a /var/www/
COPY . /var/www/

# Exponemos el puerto 9000 a la network
EXPOSE 9000

# Corremos el comando php-fpm para ejecutar PHP
CMD ["php-fpm"]
