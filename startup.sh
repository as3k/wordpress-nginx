#!/bin/bash

# Start PHP-FPM service
service php7.4-fpm start

# Set up WordPress directory
if [[ -d /var/www/wordpress ]]; then
	    mv /var/www/html /var/www/html.old
	        mv /var/www/wordpress /var/www/html
fi
chown -Rf www-data:www-data /var/www/html

# Read the domain name
echo "Enter the domain name for your WordPress site (e.g., example.com):"
read -p "Domain/Subdomain name: " DOMAIN

if [[ -z "$DOMAIN" ]]; then
	    echo "Invalid domain name. Exiting."
	        exit 1
fi

# Read WordPress admin details
echo "Enter WordPress admin username (default: admin):"
read -p "Admin Username: " WP_ADMIN
WP_ADMIN=${WP_ADMIN:-admin}

echo "Enter WordPress admin email:"
read -p "Admin Email: " WP_EMAIL

if [[ -z "$WP_EMAIL" ]]; then
	    echo "Invalid email address. Exiting."
	        exit 1
fi

echo "Enter WordPress admin password:"
read -s -p "Admin Password: " WP_PASSWORD
echo

if [[ -z "$WP_PASSWORD" ]]; then
	    echo "Invalid password. Exiting."
	        exit 1
fi

echo "Enter your WordPress site title:"
read -p "Site Title: " WP_TITLE

if [[ -z "$WP_TITLE" ]]; then
	    echo "Invalid site title. Exiting."
	        exit 1
fi

# Configure Nginx
cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Restart Nginx to apply changes
service nginx restart

# Install WordPress
echo "Installing WordPress..."
wp core install --allow-root --path="/var/www/html" \
	    --title="$WP_TITLE" \
	        --url="http://$DOMAIN" \
		    --admin_user="$WP_ADMIN" \
		        --admin_password="$WP_PASSWORD" \
			    --admin_email="$WP_EMAIL"

# Optional: Set up Let's Encrypt
echo "Would you like to configure SSL with Let's Encrypt? (y/n)"
read -r SSL_CONFIRM

if [[ "$SSL_CONFIRM" =~ ^[Yy]$ ]]; then
	    certbot --nginx -d "$DOMAIN"
fi

echo "WordPress installation complete."
echo "Access your site at: http://$DOMAIN"
if [[ "$SSL_CONFIRM" =~ ^[Yy]$ ]]; then
	    echo "Or access it securely at: https://$DOMAIN"
fi
