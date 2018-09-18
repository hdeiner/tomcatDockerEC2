#!/usr/bin/env bash

echo Stop current tomcattest Docker container
sudo -S <<< "password" docker stop tomcattest

echo Remove current tomcattest Docker container
sudo -S <<< "password" docker rm tomcattest

echo Create a fresh Docker tomcattest container
echo Starting tomcat:7.0-jre7:latest in Docker container
sudo -S <<< "password" docker run -d \
    -v $(pwd)/dist/hello-world.war:/usr/local/tomcat/webapps/hello-world.war \
    -p 8080:8080 \
    --name tomcattest \
    tomcat:7.0-jre7

echo Pause 5 seconds to allow Tomcat to start up
sleep 5

echo Smoke test
curl -s localhost:8080/hello-world/index.jsp > temp
if grep -q "<h1>Hello World!</h1>" temp
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