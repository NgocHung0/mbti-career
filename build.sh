#!/usr/bin/env bash
# Dừng ngay nếu gặp lỗi
set -e

# Cài đặt thư viện tối ưu cho Production
composer install --no-dev --optimize-autoloader

# Cache cấu hình
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Tự động chạy Migration Database
php artisan migrate --force