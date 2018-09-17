Write-host "Stop current tomcattest Docker container"
docker stop tomcattest

Write-host "Remove current tomcattest Docker container"
docker rm tomcattest

Write-host "Remove current tomcattest Docker container image"
docker rmi -f tomcattest

Write-host "Build a fresh new tomcattest Docker container"
docker build -t tomcattest .

Write-host "Starting tomcattest Docker container"
docker run --name tomcattest -d -p 8080:8080 tomcattest

Write-host "Pause 5 seconds to allow Tomcat to start up"
Start-Sleep -s 5

Write-host "Smoke test"
curl http://localhost:8080/hello-world/index.jsp > temp
if (Select-String -Pattern "<h1>Hello World!</h1>" temp) {
    Write-host "deployment was successful"
    
	Write-host "Stop the Docker Tomcat container (Windows does not allow a commit on a running container)"
    docker stop tomcattest
	
	Write-host "Commit the Docker Tomcat container as a Docker image"
    docker commit -a howarddeiner -m "finsihed provisioning" tomcattest howarddeiner/tomcattest:releasecopy

    Write-host "Authenticate to Docker Hub"
    docker login

    Write-host "Push the Docker Tomcat release image to the Docker Hub registry"
    docker push howarddeiner/tomcattest:releasecopy
} else {
    echo "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
}
rm temp