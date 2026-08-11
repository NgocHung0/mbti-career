FROM php:8.2-fpm

# Cài đặt các system dependencies & PHP extensions cần thiết cho Laravel
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt extensions (thêm pdo_pgsql để chạy được PostgreSQL trên Render)
RUN docker-php-ext-install pdo_mysql pdo_pgsql mbstring zip exif pcntl bcmath gd

# Cài đặt Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy toàn bộ code Laravel vào container
COPY . .

# Cài các gói PHP vendor
RUN composer install --no-dev --optimize-autoloader

EXPOSE 10000

# Chạy migrate và khởi động server đúng port của Render
CMD php artisan config:clear && php artisan migrate --force --seed && php artisan serve --host=0.0.0.0 --port=${PORT:-10000}