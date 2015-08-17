FROM tutum/apache-php:latest
MAINTAINER Borja Burgos <borja@tutum.co>, Feng Honglin <hfeng@tutum.co>

ENV WORDPRESS_VER 4.2.4
WORKDIR /
RUN apt-get update && \
    apt-get -yq install mysql-client curl && \
    rm -rf /app && \
    curl -0L http://wordpress.org/wordpress-${WORDPRESS_VER}.tar.gz | tar zxv && \
    mv /wordpress /app && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf
RUN a2enmod rewrite
ADD wp-config.php /app/wp-config.php
ADD run.sh /run.sh
RUN chmod +x /*.sh

# Install WP Command Line Interface for easy updates
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp && wp --info --allow-root

# Expose environment variables
ENV DB_HOST **LinkMe**
ENV DB_PORT **LinkMe**
ENV DB_NAME wordpress
ENV DB_USER admin
ENV DB_PASS **ChangeMe**
ENV WP_DEBUG false

ENV WP_SITE_TITLE "Magnet Platform Site"
ENV WP_SITE_URL "http://localhost/"
ENV WP_ADMIN admin
ENV WP_ADMIN_PASS **ChangeMe** 
ENV WP_ADMIN_EMAIL **ChangeMe**
ENV WP_LANGUAGE en_US
ENV WP_SKIP_THEME_SETUP false

# TODO replace with a real license key that matches our license manager
ENV FOURBASE_LICENSE_EMAIL "magnet_default" 
ENV FOURBASE_LICENSE_KEY "magnet_default"

ENV AWS_ACCESS_KEY_ID **ChangeMe**
ENV AWS_SECRET_ACCESS_KEY **ChangeMe**
ENV AWS_S3_BUCKET **ChangeMe**

EXPOSE 80
VOLUME ["/app/wp-content"]
CMD ["/run.sh"]
