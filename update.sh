#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

if [ ! -f /ip2location.conf ]; then
	error "Missing configuration file."
fi

USER_AGENT="Mozilla/5.0+(compatible; IP2Location/MySQL-Docker; https://hub.docker.com/r/ip2location/mysql)"
TOKEN=$(grep 'TOKEN' /ip2location.conf | cut -d= -f2)
CODE=$(grep 'CODE' /ip2location.conf | cut -d= -f2)
IP_TYPE=$(grep 'IP_TYPE' /ip2location.conf | cut -d= -f2)
MYSQL_PASSWORD=$(grep 'MYSQL_PASSWORD' /ip2location.conf | cut -d= -f2)

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

echo -n " > [MySQL] Create table \"ip2location_database_tmp\" "

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_tmp; CREATE TABLE ip2location_database_tmp LIKE ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

for CSV in $(ls | grep '.CSV'); do
	echo -n " > [MySQL] Load $CSV into database "
	RESPONSE="$(mysql ip2location_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2location_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\r\n'\''' 2>&1)"
	[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"
done

echo -n " > [MySQL] Rename table \"ip2location_database\" to \"ip2location_database_drop\" "

RESPONSE="$(mysql ip2location_database -e 'RENAME TABLE ip2location_database TO ip2location_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Rename table \"ip2location_database_tmp\" to \"ip2location_database\" "

RESPONSE="$(mysql ip2location_database -e 'RENAME TABLE ip2location_database_tmp TO ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Drop table \"ip2location_database_drop\" "

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

rm -rf /_tmp

success "   [UPDATE COMPLETED]"