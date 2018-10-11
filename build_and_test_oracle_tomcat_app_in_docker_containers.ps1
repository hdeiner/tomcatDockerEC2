Write-host "Create a Docker network for containers to communicate over"
docker network create --driver nat dockernet

Write-host "Stop and remove current Oracle and Tomcat Docker container"
docker stop oracletest tomcattest
docker rm oracletest tomcattest

Write-host "Create a fresh Docker Oracle container"
docker run -d -p 1521:1521 -p 8081:8080 -e ORACLE_ALLOW_REMOTE=true --name oracletest --network dockernet alexeiled/docker-oracle-xe-11g

Write-host "Pause 60 seconds to allow Oracle to start up"
Start-Sleep -s 60

Write-host "Create the Tomcat war, including oracleConfig.properties with oracletest baked into the Oracle url, to allow communication to the locally operating Oracle instance on the dockernet we just created"
(Get-Content oracleConfig.properties) | Foreach-Object {$_ -replace '^url\=.*$','url=jdbc:oracle:thin:@oracletest:1521/xe'} | Out-File oracleConfig.properties -encoding ASCII
mvn clean compile war:war

Write-host "Create a fresh Docker tomcattest container from the war we just created"
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
    echo "deployments were successful"

    Write-host "docker login"

    Write-host "Stop current Oracle and Tomcat Docker containers"
    docker stop oracletest tomcattest
    Write-host "Commit and push the Docker Oracle container as a Docker image"
    docker commit -a howarddeiner -m "finsihed provisioning" oracletest howarddeiner/oracletest:release
    docker push howarddeiner/oracletest:release

    Write-host "Commit and push the Docker Tomcat container as a Docker image"
    docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releasedesktoporacle
    docker push howarddeiner/tomcattest:releasedesktoporacle

    Write-host "Restart current Oracle and Tomcat Docker containers"
    docker restart oracletest tomcattest
} else {
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
}
rm temp