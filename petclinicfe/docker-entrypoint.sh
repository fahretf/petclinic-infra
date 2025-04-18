#!/bin/sh

echo "window.env = {" > /usr/share/nginx/html/config.js
echo "  REST_API_URL: '${REST_API_URL:-/petclinic/api/}'" >> /usr/share/nginx/html/config.js
echo "};" >> /usr/share/nginx/html/config.js

BACKEND_URL=${BACKEND_URL:-http://petclinicbe:9966}
sed -i "s|__BACKEND_URL__|${BACKEND_URL}|g" /etc/nginx/conf.d/default.conf

until nc -z petclinicbe 9966; do
  echo "Wait for backend to be ready"
  sleep 1
done

exec nginx -g "daemon off;"