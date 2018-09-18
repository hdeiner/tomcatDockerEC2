#!/usr/bin/env bash

echo Stop current localregistry Docker container
sudo -S <<< "password" docker stop localregistry

echo Remove current localregistry Docker container
sudo -S <<< "password" docker rm localregistry

echo Start the new localregistry Docker container
sudo -S <<< "password" docker run -d --name localregistry \
-e "REGISTRY_STORAGE=s3" \
-e "REGISTRY_STORAGE_S3_REGION=us-east-1" \
-e "REGISTRY_STORAGE_S3_BUCKET=howarddeinerdockerregistry" \
-e "REGISTRY_STORAGE_S3_ACCESSKEY=`aws configure get aws_access_key_id`" \
-e "REGISTRY_STORAGE_S3_SECRETKEY=`aws configure get aws_secret_access_key`" \
-p '80:5000' registry:2

echo tag the current tomcat Docker container just built
sudo docker commit -a localhost:80 -m "finsihed provisioning" tomcattest localhost:80/tomcattest:releasecopy

echo S3 usage before
aws s3 ls howarddeinerdockerregistry --recursive --human-readable --summarize

echo push the container to my S3 storage
sudo docker push localhost:80/tomcattest:releasecopy

echo S3 usage after
aws s3 ls howarddeinerdockerregistry --recursive --human-readable --summarize

echo list the repositories on this registry
curl localhost:80/v2/_catalog