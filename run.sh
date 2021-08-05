#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

if [ -f /config ]; then
	/etc/init.d/mysql restart >/dev/null 2>&1
	tail -f /dev/null
fi

if [ "$TOKEN" == "FALSE" ]; then
	error "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	error "Missing product code."
fi

if [ "$MYSQL_PASSWORD" == "FALSE" ]; then
	error "Missing MySQL password."
fi

if [ -z "$(echo $CODE | grep 'DB')" ]; then
	error "Download code is invalid."
fi

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Location database "

wget -O database.zip -q --user-agent="Docker-IP2Location/MySQL" http://www.ip2location.com/download?token=${TOKEN}\&productcode=${CODE} > /dev/null 2>&1

[ ! -f database.zip ] && error "[DOWNLOAD FAILED]"

[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"

[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

[ $(wc -c < database.zip) -lt 512000 ] && error "[FILE CORRUPTED]"

success "[OK]"

echo -n " > Decompress downloaded package "

unzip -q -o database.zip

if [ "$CODE" == "DB1" ]; then
	CSV="$(find . -name 'IPCountry.csv')"

elif [ "$CODE" == "DB2" ]; then
	CSV="$(find . -name 'IPISP.csv')"

elif [ ! -z "$(echo $CODE | grep 'LITE')" ]; then
	CSV="$(find . -name 'IP*.CSV')"

elif [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
	CSV="$(find . -name 'IPV6-COUNTRY*.CSV')"

else
	CSV="$(find . -name 'IP-COUNTRY*.CSV')"
fi

[ -z "$CSV" ] && error "[FILE CORRUPTED]" || success "[OK]"

/etc/init.d/mysql start > /dev/null 2>&1

echo -n " > [MySQL] Create database \"ip2location_database\" "
RESPONSE="$(mysql -e 'CREATE DATABASE IF NOT EXISTS ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[$RESPONSE]" || success "[OK]"

echo -n " > [MySQL] Create table \"ip2location_database_tmp\" "

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_tmp' 2>&1)"

case "$CODE" in
	DB1|DB1LITE|DB1IPV6|DB1LITEIPV6 )
		FIELDS=''
	;;

	DB2|DB2IPV6 )
		FIELDS=',`isp` VARCHAR(255) NOT NULL'
	;;

	DB3|DB3LITE|DB3IPV6|DB3LITEIPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL'
	;;

	DB4|DB4IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL'
	;;

	DB5|DB5LITE|DB5IPV6|DB5LITEIPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL'
	;;

	DB6|DB6IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL'
	;;

	DB7|DB7IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB8|DB8IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB9|DB9LITE|DB9IPV6|DB9LITEIPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL'
	;;

	DB10|DB10IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB11|DB11LITE|DB11IPV6|DB11LITEIPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL'
	;;

	DB12|DB12IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB13|DB13IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`net_speed` VARCHAR(8) NOT NULL'
	;;

	DB14|DB14IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL'
	;;

	DB15|DB15IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL'
	;;

	DB16|DB16IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL'
	;;

	DB17|DB17IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`net_speed` VARCHAR(8) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL'
	;;

	DB18|DB18IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL'
	;;

	DB19|DB19IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL'
	;;

	DB20|DB20IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL'
	;;

	DB21|DB21IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`elevation` INT(10) NOT NULL'
	;;

	DB22|DB22IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL'
	;;

	DB23|DB23IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`usage_type` VARCHAR(11) NOT NULL'
	;;

	DB24|DB24IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL,`usage_type` VARCHAR(11) NOT NULL'
	;;

	DB25|DB25IPV6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`address_type` CHAR(1) NULL DEFAULT NULL,`category` VARCHAR(10) NULL DEFAULT NULL'
	;;
esac

if [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
	RESPONSE="$(mysql ip2location_database -e 'CREATE TABLE ip2location_database_tmp (`ip_from` DECIMAL(39,0) UNSIGNED NOT NULL,`ip_to` DECIMAL(39,0) UNSIGNED NOT NULL,`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"
else
	RESPONSE="$(mysql ip2location_database -e 'CREATE TABLE ip2location_database_tmp (`ip_from` INT(10) UNSIGNED ZEROFILL NOT NULL,`ip_to` INT(10) UNSIGNED ZEROFILL NOT NULL,`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"
fi

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Load CSV data into \"ip2location_database_tmp\" "

RESPONSE="$(mysql ip2location_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2location_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\r\n'\''' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Drop table \"ip2location_database\" "

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Rename table \"ip2location_database_tmp\" to \"ip2location_database\" "

RESPONSE="$(mysql ip2location_database -e 'RENAME TABLE ip2location_database_tmp TO ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo " > [MySQL] Create MySQL user \"admin\""

mysql -e "CREATE USER admin@'%' IDENTIFIED BY '$MYSQL_PASSWORD'" > /dev/null 2>&1
mysql -e "GRANT ALL PRIVILEGES ON *.* TO admin@'%' WITH GRANT OPTION" > /dev/null 2>&1

echo " > Setup completed"
echo ""
echo " > You can now connect to this MySQL Server using:"
echo ""
echo "   mysql -u admin -p$MYSQL_PASSWORD ip2location_database"
echo ""

echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" > /config
echo "TOKEN=$TOKEN" >> /config
echo "CODE=$CODE" >> /config

rm -rf /_tmp

tail -f /dev/null