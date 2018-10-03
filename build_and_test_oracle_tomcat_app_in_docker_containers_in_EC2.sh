#!/usr/bin/env bash

# don't create Tomcat instances yet
sed -i -r 's/count\s+\=\s+[0-9]+/count = 0/g' terraform/terraformResourceTomcat.tf

# create the test infrasctucture for Tomcat
cd terraform
terraform init
terraform apply -auto-approve
export ORACLE=$(echo `terraform output oracle_dns`)
cd ..

echo Created Oracle on $ORACLE
echo Give Oracle 60 seconds to get online
sleep 60

# package new passwordAPI.war baking in ORACLE dns endpoint
sed -i -r 's/^url\=.*$/url=jdbc:oracle:thin:@'$ORACLE':1521\/xe/g' oracleConfig.properties
mvn clean compile war:war

echo Stop and remove current tomcattest Docker container
sudo -S <<< "password" docker stop tomcattest
sudo -S <<< "password" docker rm tomcattest

echo Create a fresh Docker tomcattest container from the war we just created
sudo -S <<< "password" docker network create dockernet
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
    echo "Tomcat deployment was successful"

    sudo docker login

    echo Commit the Docker Tomcat container as a Docker image
    sudo docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releaseawsoracle
    sudo docker push howarddeiner/tomcattest:releaseawsoracle
else
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
fi
rm temp

# now create Tomcat instances
sed -i -r 's/count\s+\=\s+[0-9]+/count = 1/g' terraform/terraformResourceTomcat.tf

# create the test infrasctucture for Tomcat
cd terraform
terraform apply -auto-approve
export TOMCAT=$(echo `terraform output tomcat_dns`)
cd ..

echo Created Tomcat on $TOMCAT
echo Give Tomcat 5 seconds to get online
sleep 5

echo Smoke test
curl -s $TOMCAT:8080/passwordAPI/passwordDB > temp
if grep -q "RESULT_SET" temp
then
    echo "deployment was successful"
else
    echo "EC2 CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
fi
rm temp
