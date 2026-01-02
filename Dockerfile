FROM php:7.3-fpm-bullseye

LABEL maintainer="lizne6z0@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

# ---------- system packages ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    git \
    curl \
    unzip \
    zip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    vim \
    && rm -rf /var/lib/apt/lists/*

# ---------- php extensions ----------
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mbstring \
    tokenizer \
    xml \
    gd \
    zip \
    opcache

# ---------- composer ----------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ---------- config ----------
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ---------- app ----------
WORKDIR /var/www/html
COPY . .

RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction || true

# ---------- permissions ----------
RUN mkdir -p storage bootstrap/cache \
  && chown -R www-data:www-data storage bootstrap/cache \
  && chmod -R 775 storage bootstrap/cache

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n"]
