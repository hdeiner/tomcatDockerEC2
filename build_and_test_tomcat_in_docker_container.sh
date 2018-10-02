#!/usr/bin/env bash

echo Stop current tomcattest Docker container
sudo -S <<< "password" docker stop tomcattest

echo Remove current tomcattest Docker container
sudo -S <<< "password" docker rm tomcattest

echo Create a fresh Docker tomcattest container
echo Starting passwordAPI in Docker container
sudo -S <<< "password" docker run -d \
    -v $(pwd)/target/passwordAPI.war:/usr/local/tomcat/webapps/passwordAPI.war \
    -p 8080:8080 \
    --name tomcattest \
    tomcat:9.0.8-jre8

echo Pause 5 seconds to allow Tomcat to start up
sleep 5

echo Smoke test
curl -s http://localhost:8080/passwordAPI/passwordRules/abcde > temp
if grep -q "\{\"password\"\: \"abcde\",\"passwordRules\"\:\"password must be at least 8 characters long\"\}" temp
then
    echo "deployment was successful"
    echo Commit the Docker Tomcat container as a Docker image
    sudo docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releasecopy

    echo Authenticate to Docker Hub
    sudo docker login

    echo Push the Docker Tomcat release image to the Docker Hub registry
    sudo docker push howarddeiner/tomcattest:releasecopy
else
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
fi
rm temp