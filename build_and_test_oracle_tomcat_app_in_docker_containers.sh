#!/usr/bin/env bash

echo Create a Docker network for containers to communicate over
sudo -S <<< "password" docker network create dockernet

echo Stop and remove current Oracle and Tomcat Docker container
sudo -S <<< "password" docker stop oracletest tomcattest
sudo -S <<< "password" docker rm oracletest tomcattest

echo Create a fresh Docker Oracle container
sudo -S <<< "password" docker run \
    -d -p 1521:1521 -p 8081:8080 -e ORACLE_ALLOW_REMOTE=true \
    --name oracletest --network dockernet \
    alexeiled/docker-oracle-xe-11g

echo Pause 60 seconds to allow Oracle to start up
sleep 60

echo Create the Tomcat war, including oracleConfig.properties with oracletest baked into the Oracle url, to allow communication to the locally operating Oracle instance on the dockernet we just created
sed -i -r 's/^url\=.*$/url=jdbc:oracle:thin:@oracletest:1521\/xe/g' oracleConfig.properties
mvn clean compile war:war

echo Create a fresh Docker tomcattest container from the war we just created
sudo -S <<< "password" docker run -d \
    -p 8080:8080 \
    --name tomcattest --network dockernet \
    tomcat:9.0.8-jre8

echo Pause 5 seconds to allow Tomcat to start up
sleep 5

echo Deploy the war to Tomcat
sudo -S <<< "password" docker cp $(pwd)/target/passwordAPI.war tomcattest:/usr/local/tomcat/webapps/passwordAPI.war

echo Pause 10 seconds to allow Tomcat to digest
sleep 10

echo Smoke test
curl -s http://localhost:8080/passwordAPI/passwordDB > temp
if grep -q "RESULT_SET" temp
then
    echo "deployments were successful"

    sudo docker login

    echo Commit and push the Docker Oracle container as a Docker image
    sudo docker commit -a howarddeiner -m "finsihed provisioning" oracletest howarddeiner/oracletest:release
    sudo docker push howarddeiner/oracletest:release

    echo Commit and push the Docker Tomcat container as a Docker image
    sudo docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releasedesktoporacle
    sudo docker push howarddeiner/tomcattest:releasedesktoporacle
else
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
fi
rm temp