#!/usr/bin/env bash

# create the test infrasctucture
cd terraform
terraform init
terraform apply -auto-approve
export TOMCAT=$(echo `terraform output tomcat_dns`)
cd ..

echo Created Tomcat on $TOMCAT
echo Give Tomcat 5 seconds to get online
sleep 5

echo Smoke test
curl -s $TOMCAT:8080/hello-world/index.jsp > temp
if grep -q "<h1>Hello World!</h1>" temp
then
    echo "deployment was successful"
else
    echo "EC2 CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
fi
rm temp
