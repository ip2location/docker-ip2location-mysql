#!/bin/bash
if [ "$USERNAME" != "FALSE" ] && [ "$PASSWORD" != "FALSE" ] && [ "$CODE" != "FALSE" ] && [ ! -f /setup_done ]; then
	echo "=> Create directory /_tmp"
	mkdir /_tmp

	if [ ! -d /_tmp ]; then
		echo "=> Unable to create directory /_tmp"
		exit 1
	fi

	cd /_tmp

	echo "=> Download ${CODE} package"
	wget -O database.zip -q --user-agent="Docker-IP2Location/MySQL" http://www.ip2location.com/download?login=${USERNAME}\&password=${PASSWORD}\&productcode=${CODE} 2>&1

	if [ ! -f database.zip ]; then
		echo "=> Download failed"
		exit 1
	fi

	if [ ! -z "$(grep 'NO PERMISSION' database.zip)" ]; then
		 echo "=> Permission denied"
		exit 1
	fi

	if [ ! -z "$(grep '5 times' database.zip)" ]; then
		 echo "=> Download quota exceed"
		exit 1
	fi

	if [ $(wc -c < database.zip) -lt 102400 ]; then
		echo "=> Download failed"
		exit 1	
	fi

	echo "=> Decompress downloaded package"
	
	unzip -q -o database.zip

	if [ "$CODE" == "DB1CSV" ]; then
		CSV="$(find . -name 'IPCountry.csv')"

	elif [ "$CODE" == "DB2CSV" ]; then
		CSV="$(find . -name 'IPISP.csv')"

	elif [ ! -z "$(echo $CODE | grep 'LITE')" ]; then
		CSV="$(find . -name 'IP2LOCATION-LITE-DB*.CSV')"

	elif [ ! -z "$(echo $CODE | grep 'LITECSVIPV6')" ]; then
		CSV="$(find . -name 'IP2LOCATION-LITE-DB*.IPV6.CSV')"

	elif [ ! -z "$(echo $CODE | grep 'CSVIPV6')" ]; then
		CSV="$(find . -name 'IPV6-COUNTRY*.CSV')"

	else
		CSV="$(find . -name 'IP-COUNTRY*.CSV')"

	fi

	if [ -z "$CSV" ]; then
		echo "=> Downloaded package is corrupted"
		exit 1
	fi
	
	echo "=> Starting MySQL server..."
	/usr/bin/mysqld_safe > /dev/null 2>&1 &

	RET=1
	while [[ RET -ne 0 ]]; do
		echo "=> Waiting MySQL service to start..."
		sleep 5
		mysql -u root -e "status" > /dev/null 2>&1
		RET=$?
	done

	echo "=> [MySQL] Create database \"ip2location_database\""
	RESPONSE="$(mysql -u root -e 'CREATE DATABASE IF NOT EXISTS ip2location_database' 2>&1)"

	if [ ! -z "$(echo $RESPONSE)" ]; then
		echo "=> [MySQL] Unable to create databse \"ip2location_database\""
	fi

	echo "=> [MySQL] Create table \"ip2location_database_tmp\""

	RESPONSE="$(mysql -u root ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_tmp' 2>&1)"

	case "$CODE" in
		DB1CSV|DB1LITECSV|DB1CSVIPV6|DB1LITECSVIPV6 )
			FIELDS=''
		;;
		DB2CSV|DB2CSVIPV6 )
			FIELDS=',`isp` VARCHAR(255) NOT NULL'
		;;

		DB3CSV|DB3LITECSV|DB3CSVIPV6|DB3LITECSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL'
		;;

		DB4CSV|DB4CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL'
		;;

		DB5CSV|DB5LITECSV|DB5CSVIPV6|DB5LITECSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL'
		;;

		DB6CSV|DB6CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL'
		;;

		DB7CSV|DB7CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
		;;

		DB8CSV|DB8CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
		;;

		DB9CSV|DB9LITECSV|DB9CSVIPV6|DB9LITECSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL'
		;;

		DB10CSV|DB10CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
		;;

		DB11CSV|DB11LITECSV|DB11CSVIPV6|DB11LITECSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL'
		;;

		DB12CSV|DB12CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
		;;

		DB13CSV|DB13CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`net_speed` VARCHAR(8) NOT NULL'
		;;

		DB14CSV|DB14CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL'
		;;

		DB15CSV|DB15CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL'
		;;

		DB16CSV|DB16CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL'
		;;

		DB17CSV|DB17CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`net_speed` VARCHAR(8) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL'
		;;

		DB18CSV|DB18CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL'
		;;

		DB19CSV|DB19CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL'
		;;

		DB20CSV|DB20CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL'
		;;

		DB21CSV|DB21CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`elevation` INT(10) NOT NULL'
		;;

		DB22CSV|DB22CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL'
		;;

		DB23CSV|DB23CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`usage_type` VARCHAR(11) NOT NULL'
		;;

		DB24CSV|DB24CSVIPV6 )
			FIELDS=',`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`latitude` DOUBLE NULL DEFAULT NULL,`longitude` DOUBLE NULL DEFAULT NULL,`zip_code` VARCHAR(30) NULL DEFAULT NULL,`time_zone` VARCHAR(8) NULL DEFAULT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`net_speed` VARCHAR(8) NOT NULL,`idd_code` VARCHAR(5) NOT NULL,`area_code` VARCHAR(30) NOT NULL,`weather_station_code` VARCHAR(10) NOT NULL,`weather_station_name` VARCHAR(128) NOT NULL,`mcc` VARCHAR(128) NULL DEFAULT NULL,`mnc` VARCHAR(128) NULL DEFAULT NULL,`mobile_brand` VARCHAR(128) NULL DEFAULT NULL,`elevation` INT(10) NOT NULL,`usage_type` VARCHAR(11) NOT NULL'
		;;
	esac

	if [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
		RESPONSE="$(mysql -u root ip2location_database -e 'CREATE TABLE `ip2location_database_tmp` (`ip_from` DECIMAL(39,0) UNSIGNED NOT NULL,`ip_to` DECIMAL(39,0) UNSIGNED NOT NULL,`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"
	else
		RESPONSE="$(mysql -u root ip2location_database -e 'CREATE TABLE `ip2location_database_tmp` (`ip_from` INT(10) UNSIGNED ZEROFILL NOT NULL,`ip_to` INT(10) UNSIGNED ZEROFILL NOT NULL,`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"
	fi

	if [ ! -z "$(echo $RESPONSE)" ]; then
		echo "=> [MySQL] Unable to create table \"ip2location_database_tmp\""
		exit 1
	fi

	echo "=> [MySQL] Load CSV data into \"ip2location_database_tmp\""

	RESPONSE="$(mysql -u root ip2location_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE `ip2location_database_tmp` FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\r\n'\''' 2>&1)"

	if [ ! -z "$(echo $RESPONSE)" ]; then
		echo "=> [MySQL] Unable to load CSV data into \"ip2location_database_tmp\""
		exit 1
	fi

	echo "=> [MySQL] Drop table \"ip2location_database\""

	RESPONSE="$(mysql -u root ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database' 2>&1)"

	if [ ! -z "$(echo $RESPONSE)" ]; then
		echo "=> [MySQL] Unable to drop table \"ip2location_database\""
		exit 1
	fi

	echo "=> [MySQL] Rename table \"ip2location_database_tmp\" to \"ip2location_database\""

	RESPONSE="$(mysql -u root ip2location_database -e 'RENAME TABLE ip2location_database_tmp TO ip2location_database' 2>&1)"

	if [ ! -z "$(echo $RESPONSE)" ]; then
		echo "=> [MySQL] Unable to rename table \"ip2location_database_tmp\""
		exit 1
	fi

	if [ "$MYSQL_PASSWORD" != "FALSE" ]; then
		DBPASS="$MYSQL_PASSWORD"
	else
		DBPASS="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c8)"	
	fi

	echo "=> [MySQL] Create MySQL user \"admin\""

	mysql -u root -e "CREATE USER admin@'%' IDENTIFIED BY '$DBPASS'" > /dev/null 2>&1
	mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO admin@'%' WITH GRANT OPTION" > /dev/null 2>&1

	echo "=> Setup completed"
	echo ""
	echo "=> You can now connect to this MySQL Server using:"
	echo ""
	echo "   mysql -u admin -p$DBPASS ip2location_database"
	echo ""

	rm -rf /_tmp
	echo '' > /setup_done
	mysqladmin -u root shutdown
	sleep 5
fi

/usr/bin/mysqld_safe > /dev/null 2>&1