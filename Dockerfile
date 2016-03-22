FROM tutum/apache-php:latest
MAINTAINER Borja Burgos <borja@tutum.co>, Feng Honglin <hfeng@tutum.co>

ENV WORDPRESS_VER 4.4
WORKDIR /
RUN apt-get update && \
    apt-get -yq install mysql-client curl wget && \
    rm -rf /app && \
    curl -0L http://wordpress.org/wordpress-${WORDPRESS_VER}.tar.gz | tar zxv && \
    mv /wordpress /app && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen fi_FI
RUN locale-gen fi_FI.UTF-8

RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

# Increase upload size
RUN sed -i.bak 's/upload_max_filesize = 2M/upload_max_filesize = 64M/g' /etc/php5/apache2/php.ini && \
    sed -i.bak 's/post_max_size = 8M/post_max_size = 64M/g' /etc/php5/apache2/php.ini

RUN a2enmod rewrite
ADD wp-config.php /app/wp-config.php
ADD wp-htaccess /app/.htaccess
ADD run.sh /run.sh
RUN chmod +x /*.sh

# Install WP Command Line Interface for easy updates
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp && wp --info --allow-root

RUN locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8 && \
    echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list && \
    wget -O - https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - && \
    echo newrelic-php5 newrelic-php5/application-name string "NEWRELIC_APP" | debconf-set-selections && \
    echo newrelic-php5 newrelic-php5/license-key string "NEWRELIC_LICENSE" | debconf-set-selections;

RUN sudo apt-get update && \
    sudo apt-get -yq install newrelic-php5 && \
    php5dismod newrelic

# Prevent newrelic daemon from auto-spawning; uses newrelic run.d script to enable at runtime, when ENV variables are present
# @see https://docs.newrelic.com/docs/agents/php-agent/advanced-installation/starting-php-daemon-advanced
RUN sed -i "s/;newrelic.daemon.dont_launch = 0/newrelic.daemon.dont_launch = 3/" /etc/php5/mods-available/newrelic.ini


# Expose environment variables
ENV DB_HOST **LinkMe**
ENV DB_PORT **LinkMe**
ENV DB_NAME wordpress
ENV DB_USER admin
ENV DB_PASS **ChangeMe**
ENV WP_DEBUG false
ENV WP_DEBUG_DISPLAY false

ENV WP_SITE_TITLE "Magnet Platform Site"
ENV WP_SITE_URL "http://localhost/"
ENV WP_ADMIN admin
ENV WP_ADMIN_PASS **ChangeMe** 
ENV WP_ADMIN_EMAIL **ChangeMe**
ENV WP_LANGUAGE en_US

# TODO replace with a real license key that matches our license manager
ENV FOURBASE_LICENSE_EMAIL "magnet_default" 
ENV FOURBASE_LICENSE_KEY "magnet_default"

ENV SHOW_MENU_PAGES 0

ENV AKISMET_API_KEY **ChangeMe**

ENV MAXMIND_USER_ID **ChangeMe**
ENV MAXMIND_LICENSE_KEY **ChangeMe**
ENV MAXMIND_DEFAULT_COUNTRY US

ENV MANDRILL_USERNAME **ChangeMe**
ENV MANDRILL_API_KEY **ChangeMe**
ENV MANDRILL_ENABLED 1

ENV AWS_ACCESS_KEY_ID **ChangeMe**
ENV AWS_SECRET_ACCESS_KEY **ChangeMe**
ENV AWS_S3_BUCKET **ChangeMe**

EXPOSE 80
VOLUME ["/app/wp-content"]
CMD ["/run.sh"]
