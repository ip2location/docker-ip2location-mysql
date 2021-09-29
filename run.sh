#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

USER_AGENT="Mozilla/5.0+(compatible; IP2Location/MySQL-Docker; https://hub.docker.com/r/ip2location/mysql)"
CODES=("DB1-LITE DB3-LITE DB5-LITE DB9-LITE DB11-LITE DB1 DB2 DB3 DB4 DB5 DB6 DB7 DB8 DB9 DB10 DB11 DB12 DB13 DB14 DB15 DB16 DB17 DB18 DB19 DB20 DB21 DB22 DB23 DB24 DB25")

if [ -f /ip2location.conf ]; then
	/etc/init.d/mysql restart >/dev/null 2>&1
	tail -f /dev/null
fi

if [ "$TOKEN" == "FALSE" ]; then
	error "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	error "Missing database code."
fi

if [ "$MYSQL_PASSWORD" == "FALSE" ]; then
	MYSQL_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})"
fi

FOUND=""
for i in "${CODES[@]}"; do
	if [ "$i" == "$CODE" ] ; then
		FOUND="$CODE"
	fi
done

if [ -z $FOUND == "" ]; then
	error "Download code is invalid."
fi

CODE=$(echo $CODE | sed 's/-//')

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Location database "

if [ "$IP_TYPE" == "IPV4" ]; then
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
elif [ "$IP_TYPE" == "IPV6" ]; then
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
else
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4.zip)" ] && error "[QUOTA EXCEEDED]"

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)
	[ $? -ne 0 ] && error "[FILE CORRUPTED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)
	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
fi

success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | grep '.CSV' | awk '{ print $4 }')

	echo -n " > Decompress $CSV from $ZIP "

	unzip -jq $ZIP $CSV

	if [ ! -f $CSV ]; then
		error "[ERROR]"
	fi

	success "[OK]"
done

/etc/init.d/mysql start > /dev/null 2>&1

echo -n " > [MySQL] Create database \"ip2location_database\" "
RESPONSE="$(mysql -e 'CREATE DATABASE IF NOT EXISTS ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[$RESPONSE]" || success "[OK]"

echo -n " > [MySQL] Create table \"ip2location_database_tmp\" "

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_tmp' 2>&1)"

case "$CODE" in
	DB1|DB1LITE )
		FIELDS=''
	;;

	DB2 )
		FIELDS=',`isp` VARCHAR(255) NOT NULL'
	;;

	DB3|DB3LITE )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL'
	;;

	DB4 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL'
	;;

	DB5|DB5LITE )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL'
	;;

	DB6 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL'
	;;

	DB7 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB8 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB9|DB9LITE )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL'
	;;

	DB10 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB11|DB11LITE )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL'
	;;

	DB12 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	DB13 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`net_speed` VARCHAR(8) NOT NULL'
	;;

	DB14 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL'
	;;

	DB15 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL'
	;;

	DB16 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL'
	;;

	DB17 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`net_speed` VARCHAR(8) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL'
	;;

	DB18 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL'
	;;

	DB19 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL'
	;;

	DB20 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL'
	;;

	DB21 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`elevation` INT(10) NOT NULL'
	;;

	DB22 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL'
	;;

	DB23 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`usage_type` VARCHAR(11) NOT NULL'
	;;

	DB24 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL,`usage_type` VARCHAR(11) NOT NULL'
	;;

	DB25 )
		FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`address_type` CHAR(1) NULL DEFAULT NULL,`category` VARCHAR(10) NULL DEFAULT NULL'
	;;
esac

RESPONSE="$(mysql ip2location_database -e 'CREATE TABLE ip2location_database_tmp (`ip_from` DECIMAL(39,0) UNSIGNED NOT NULL,`ip_to` DECIMAL(39,0) UNSIGNED NOT NULL,`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

for CSV in $(ls | grep '.CSV'); do
	echo -n " > [MySQL] Load $CSV into database "
	RESPONSE="$(mysql ip2location_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2location_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\r\n'\''' 2>&1)"
	[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"
done

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

echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" > /ip2location.conf
echo "TOKEN=$TOKEN" >> /ip2location.conf
echo "CODE=$CODE" >> /ip2location.conf
echo "IP_TYPE=$IP_TYPE" >> /ip2location.conf

rm -rf /_tmp

tail -f /dev/null