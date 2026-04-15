#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source .env

echo "🔐 Initializing Let's Encrypt certificates..."
echo "   Domain: ${DOMAIN}"
echo "   Email: ${LETSENCRYPT_EMAIL}"

# Generate configs
echo "📝 Generating configs..."
make config

# Create temp nginx config for certbot
echo "🔧 Creating temporary nginx config for ACME challenge..."
cat > nginx/nginx-certbot.conf << EOF
events {}
http {
    server {
        listen 80;
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
    }
}
EOF

# Backup main config and use temp config
mv nginx/nginx.conf nginx/nginx.conf.bak
cp nginx/nginx-certbot.conf nginx/nginx.conf

# Start nginx for ACME challenge
echo "🚀 Starting nginx with temp config..."
docker compose up -d --no-deps nginx
sleep 5

# Request certificates
echo "📜 Requesting certificates from Let's Encrypt..."
docker run --rm \
    --network talaria_internal \
    -v $(pwd)/certbot/conf:/etc/letsencrypt \
    -v $(pwd)/certbot/www:/var/www/certbot \
    certbot/certbot:latest \
    certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${LETSENCRYPT_EMAIL} \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    --non-interactive \
    -d ${DOMAIN}

# Restore main config
echo "🔄 Restoring main nginx config..."
mv nginx/nginx.conf.bak nginx/nginx.conf

# Create symlink for nginx
echo "🔗 Creating symlinks..."
ln -sf ../certbot/conf/live/${DOMAIN} nginx/ssl/live

# Copy certificates for 3X-UI and Telemt
echo "📋 Copying certificates for services..."
mkdir -p 3x-ui/cert
cp certbot/conf/live/${DOMAIN}/fullchain.pem 3x-ui/cert/
cp certbot/conf/live/${DOMAIN}/privkey.pem 3x-ui/cert/

# Restart nginx with main config
echo "🔄 Restarting nginx with main config..."
docker compose restart nginx

echo ""
echo "✅ Certificates installed successfully!"
echo "   Main domain: https://${DOMAIN}"
echo "   3X-UI panel: https://${DOMAIN}/${XUI_PATH}/"