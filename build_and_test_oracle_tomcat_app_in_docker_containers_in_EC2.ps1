# don't create Tomcat instances yet
(Get-Content terraform/terraformResourceTomcat.tf) | Foreach-Object {$_ -replace 'count\s*\=\s*[0-9]+','count = 0'} | Out-File terraform/terraformResourceTomcat.tf -encoding ASCII

# create the test infrasctucture for Oracle
cd terraform
terraform init
terraform apply -auto-approve
$ORACLE=terraform output oracle_dns
cd ..

Write-host "Created Oracle on " $ORACLE
Write-host "Give Oracle 60 seconds to get online"
Start-Sleep -s 60

# package new passwordAPI.war baking in ORACLE dns endpoint
$JDBCURL="url=jdbc:oracle:thin:@" + $ORACLE + ":1521/xe"
(Get-Content oracleConfig.properties) | Foreach-Object {$_ -replace '^url\=.*$',$JDBCURL} | Out-File oracleConfig.properties -encoding ASCII
mvn clean compile war:war

Write-host "Stop and remove current Tomcat Docker container"
docker stop tomcattest
docker rm tomcattest

Write-host "Create a fresh Docker tomcattest container from the war we just created"
docker network create --driver nat dockernet
docker run -d -p 8080:8080 --name tomcattest --network dockernet tomcat:9.0.8-jre8

Write-host "Pause 15 seconds to allow Tomcat to start up"
Start-Sleep -s 15

Write-host "Stop current Tomcat Docker container"
docker stop tomcattest
Write-host "Deploy the war to Tomcat"
docker cp .\target\passwordAPI.war tomcattest:/usr/local/tomcat/webapps/passwordAPI.war
Write-host "Restart current Tomcat Docker container"
docker restart tomcattest

Write-host "Pause 10 seconds to allow Tomcat to digest"
Start-Sleep -s 10

Write-host "Smoke test"
curl http://localhost:8080/passwordAPI/passwordDB > temp
if (Get-Content temp | Select-String("RESULT_SET")) {
    Write-host "deployments were successful"

    Write-host "docker login"

    Write-host "Stop current Tomcat Docker container"
    docker stop tomcattest

    Write-host "Commit and push the Docker Tomcat container as a Docker image"
    docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releaseawsoracle
    docker push howarddeiner/tomcattest:releaseawsoracle

    Write-host "Restart current Tomcat Docker container"
    docker restart tomcattest
} else {
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
}
rm temp

(Get-Content terraform/terraformResourceTomcat.tf) | Foreach-Object {$_ -replace 'count\s*\=\s*[0-9]+','count = 1'} | Out-File terraform/terraformResourceTomcat.tf -encoding ASCII

# create the test infrasctucture for Tomcat
cd terraform
terraform apply -auto-approve
$TOMCAT=terraform output tomcat_dns
cd ..

Write-host "Created Tomcat on " $TOMCAT
Write-host "Give Tomcat 10 seconds to get online"
Start-Sleep -s 10

Write-host "Smoke test"
$URI="http://" + $TOMCAT + ":8080/passwordAPI/passwordDB"
curl -Uri $URI > temp
if (Get-Content temp | Select-String("RESULT_SET")) {
    Write-host "deployment was successful"
} else {
    Write-host "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
}
rm temp