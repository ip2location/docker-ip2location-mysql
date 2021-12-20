#!/bin/bash

text_primary() { echo -n " $1 $(printf '\055%.0s' {1..80})" | head -c 80; echo -n ' '; }
text_success() { printf "\e[00;92m%s\e[00m\n" "$1"; }
text_danger() { printf "\e[00;91m%s\e[00m\n" "$1"; exit 0; }

[ ! -f /ip2location.conf ] && text_danger "Missing configuration file."

USER_AGENT="Mozilla/5.0+(compatible; IP2Location/MySQL-Docker; https://hub.docker.com/r/ip2location/mysql)"
TOKEN=$(grep 'TOKEN' /ip2location.conf | cut -d= -f2)
CODE=$(grep 'CODE' /ip2location.conf | cut -d= -f2)
IP_TYPE=$(grep 'IP_TYPE' /ip2location.conf | cut -d= -f2)
MYSQL_PASSWORD=$(grep 'MYSQL_PASSWORD' /ip2location.conf | cut -d= -f2)

rm -rf /_tmp && mkdir /_tmp && cd /_tmp

text_primary " > Download IP2Location database"

if [ "$IP_TYPE" == "IPV4" ]; then
	wget -qO ipv4.zip --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' database.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
elif [ "$IP_TYPE" == "IPV6" ]; then
	wget -qO ipv6.zip --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' database.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
else
	wget -qO ipv4.zip --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1
	wget -qO ipv6.zip --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)
	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)
	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
fi

text_success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | grep '.CSV' | awk '{ print $4 }')

	text_primary " > Decompress $CSV from $ZIP"

	unzip -oq $ZIP $CSV

	if [ ! -f $CSV ]; then
		text_danger "[ERROR]"
	fi

	text_success "[OK]"
done

text_primary " > [MySQL] Create table \"ip2location_database_tmp\""

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_tmp; CREATE TABLE ip2location_database_tmp LIKE ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_danger "[ERROR]" || text_success "[OK]"

for CSV in $(ls | grep '.CSV'); do
	text_primary " > [MySQL] Load $CSV into database"
	RESPONSE="$(mysql ip2location_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2location_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\r\n'\''' 2>&1)"
	[ ! -z "$(echo $RESPONSE)" ] && text_danger "[ERROR]" || text_success "[OK]"
done

text_primary " > [MySQL] Rename table \"ip2location_database\" to \"ip2location_database_drop\""

RESPONSE="$(mysql ip2location_database -e 'RENAME TABLE ip2location_database TO ip2location_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [MySQL] Rename table \"ip2location_database_tmp\" to \"ip2location_database\""

RESPONSE="$(mysql ip2location_database -e 'RENAME TABLE ip2location_database_tmp TO ip2location_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [MySQL] Drop table \"ip2location_database_drop\""

RESPONSE="$(mysql ip2location_database -e 'DROP TABLE IF EXISTS ip2location_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_danger "[ERROR]" || text_success "[OK]"

rm -rf /_tmp

text_success "  > [UPDATE COMPLETED]"