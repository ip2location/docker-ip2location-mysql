docker-ip2location-mysql
========================

This is a pre-configured, ready-to-run MySQL server with IP2Location Geolocation database setup scripts. It simplifies the development team to install and set up the geolocation database in MySQL server. The setup script supports the [commercial database packages](http://www.ip2location.com) and [free LITE package](http://lite.ip2location.com). Please register for a download account before running this image.

### Usage

1. Run this image as daemon with your username, password, and download code registered from [IP2Location](http://www.ip2location.com).

        docker run --name ip2location -d -e MYSQL_PASSWORD=YOUR_MYSQL_PASSWORD -e USERNAME=YOUR_USERNAME -e PASSWORD=YOUR_PASSWORD -e CODE=DOWNLOAD_CODE ip2location/mysql

    **ENV VARIABLE**

    MYSQL_PASSWORD – Enter a password for user admin.

    USERNAME – Email address of the registered download account.

    PASSWORD – Password of the registered download account.

    CODE – The CSV file download code. You may get the download code from your account panel.

2. The installation may take minutes to hour depending on your internet speed and hardware. You may check the installation status by viewing the container logs. Run the below command to check the container log:

        docker logs YOUR_CONTAINER_ID
  
    You should see the line of `=> Setup completed` if you have successfully complete the installation.

### Connect to it from an application

    docker run --link ip2location:ip2location-db -t -i application_using_the_ip2location_data

### Make the query

    mysql -u admin -pYOUR_MYSQL_PASSWORD -h ip2location-db ip2location_database -e 'SELECT * FROM `ip2location_database` WHERE INET_ATON("8.8.8.8") <= ip_to LIMIT 1'