#!/usr/bin/env bash

echo Create a Docker network for containers to communicate over
sudo -S <<< "password" docker network create dockernet

echo Stop current Oracle Docker container
sudo -S <<< "password" docker stop oracletest

echo Remove current Oracle Docker container
sudo -S <<< "password" docker rm oracletest

echo Create a fresh Docker Oracle container
sudo -S <<< "password" docker run \
    -d -p 1521:1521 -p 8081:8080 -e ORACLE_ALLOW_REMOTE=true \
    --name oracletest --network dockernet \
    alexeiled/docker-oracle-xe-11g

echo Pause 60 seconds to allow Oracle to start up
sleep 60

echo Create the Tomcat war, including oracleConfig.properties
mvn clean compile war:war

echo Stop current tomcattest Docker container
sudo -S <<< "password" docker stop tomcattest

echo Remove current tomcattest Docker container
sudo -S <<< "password" docker rm tomcattest

echo Create a fresh Docker tomcattest container from the war we just created
sudo -S <<< "password" docker run -d \
    -v $(pwd)/target/passwordAPI.war:/usr/local/tomcat/webapps/passwordAPI.war \
    -p 8080:8080 \
    --name tomcattest --network dockernet \
    tomcat:9.0.8-jre8

echo Pause 5 seconds to allow Tomcat to start up
sleep 5

echo Smoke test
curl -s http://localhost:8080/passwordAPI/passwordDB > temp
if grep -q "RESULT_SET" temp
then
    echo "deployments were successful"

    echo Commit the Docker Oracle container as a Docker image
    sudo docker commit -a howarddeiner -m "finsihed provisioning" oracletest howarddeiner/oracletest:releasecopy

    echo Commit the Docker Tomcat container as a Docker image
    sudo docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releasecopy
else
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
fi
rm temp