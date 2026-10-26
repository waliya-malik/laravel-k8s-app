FROM laravel-3tier-k8s-base:latest

WORKDIR /var/www/html

RUN rm -rf /var/www/html/* /var/www/html/.env

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY . .

RUN composer dump-autoload --optimize \
    && cp -n .env.example .env \
    && php artisan key:generate --force \
    && chmod -R 777 storage bootstrap/cache \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["sh", "-c", "until php artisan migrate --force; do echo 'waiting for mysql'; sleep 5; done; chown -R www-data:www-data storage; apache2-foreground"]
