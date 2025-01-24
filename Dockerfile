# Use a slim Ubuntu base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get install -y \
    nginx \
    php-fpm \
    php-mysql \
    mysql-client \
    wget \
    unzip \
    certbot \
    python3-certbot-nginx \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Create the WordPress directory
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

# Copy custom scripts
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Expose ports 80 and 443
EXPOSE 80 443

# Set the entrypoint script
ENTRYPOINT ["/usr/local/bin/startup.sh"]
