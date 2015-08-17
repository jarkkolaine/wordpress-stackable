#!/bin/bash

chown www-data:www-data /app -R
chmod -R 777 /app/wp-content

DB_HOST=${DB_PORT_3306_TCP_ADDR:-${DB_HOST}}
DB_HOST=${DB_1_PORT_3306_TCP_ADDR:-${DB_HOST}}
DB_PORT=${DB_PORT_3306_TCP_PORT:-${DB_PORT}}
DB_PORT=${DB_1_PORT_3306_TCP_PORT:-${DB_PORT}}

if [ "$DB_PASS" = "**ChangeMe**" ] && [ -n "$DB_1_ENV_MYSQL_PASS" ]; then
    DB_PASS="$DB_1_ENV_MYSQL_PASS"
fi

echo "=> Using the following MySQL/MariaDB configuration:"
echo "========================================================================"
echo "      Database Host Address:  $DB_HOST"
echo "      Database Port number:   $DB_PORT"
echo "      Database Name:          $DB_NAME"
echo "      Database Username:      $DB_USER"
echo "========================================================================"

if [ -f /.mysql_db_created ]; then
        source /etc/apache2/envvars
        exec apache2 -D FOREGROUND
fi

for ((i=0;i<10;i++))
do
    DB_CONNECTABLE=$(mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT -e 'status' >/dev/null 2>&1; echo "$?")
    if [[ DB_CONNECTABLE -eq 0 ]]; then
        break
    fi
    sleep 5
done

if [[ $DB_CONNECTABLE -eq 0 ]]; then
    DB_EXISTS=$(mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT -e "SHOW DATABASES LIKE '"$DB_NAME"';" 2>&1 |grep "$DB_NAME" > /dev/null ; echo "$?")

    if [[ DB_EXISTS -eq 1 ]]; then
        echo "=> Creating database $DB_NAME"
        RET=$(mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT -e "CREATE DATABASE $DB_NAME")
        if [[ RET -ne 0 ]]; then
            echo "Cannot create database for wordpress"
            exit RET
        fi
        if [ -f /initial_db.sql ]; then
            echo "=> Loading initial database data to $DB_NAME"
            RET=$(mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT $DB_NAME < /initial_db.sql)
            if [[ RET -ne 0 ]]; then
                echo "Cannot load initial database data for wordpress"
                exit RET
            fi
        fi
        echo "=> Done!"    
    else
        echo "=> Skipped creation of database $DB_NAME – it already exists."
    fi
else
    echo "Cannot connect to Mysql"
    exit $DB_CONNECTABLE
fi

touch /.mysql_db_created
cd /app

# Install WordPress if not yet installed 
if ! $(wp --allow-root core is-installed); then
	if [ "$WP_ADMIN_PASS" = "**ChangeMe**" ]; then
		echo "Please set WP_ADMIN_PASS"
		exit -1
	fi
	if [ "$WP_ADMIN_EMAIL" = "**ChangeMe**" ]; then
		echo "Please set WP_ADMIN_EMAIL"
		exit -1
	fi

	echo "Installing WordPress"
    RET=$(wp --allow-root --quiet core install --title="$WP_SITE_TITLE" --admin_user=$WP_ADMIN --admin_password=$WP_ADMIN_PASS --admin_email=$WP_ADMIN_EMAIL --url=$WP_SITE_URL)    
fi

# Select language
echo "Activating language: $WP_LANGUAGE"
$(wp --allow-root --quiet core language activate $WP_LANGUAGE)

if [ "$AWS_ACCESS_KEY_ID" = "**ChangeMe**" ]; then
	echo "Please set AWS_ACCESS_KEY_ID"
	exit -1
fi
if [ "$AWS_SECRET_ACCESS_KEY" = "**ChangeMe**" ]; then
	echo "Please set AWS_SECRET_ACCESS_KEY"
	exit -1
fi
if [ "$AWS_S3_BUCKET" = "**ChangeMe**" ]; then
	echo "Please set AWS_S3_BUCKET"
	exit -1
fi

echo "Updating WordPress to latest version"
$(wp --allow-root --quiet core update)
$(wp --allow-root --quiet core update-db)
$(wp --allow-root --quiet core language update)

echo "Activating required plugins"
$(wp --allow-root --quiet plugin activate fourbean-membership)
$(wp --allow-root --quiet plugin activate shortcode-elements)
$(wp --allow-root --quiet plugin activate amazon-web-services)
$(wp --allow-root --quiet plugin activate amazon-s3-and-cloudfront)

echo "Starting Apache"
source /etc/apache2/envvars
exec apache2 -D FOREGROUND
