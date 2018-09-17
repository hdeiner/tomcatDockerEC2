# create the test infrasctucture
cd terraform
terraform init
terraform apply -auto-approve
$TOMCAT=terraform output tomcat_dns
cd ..

Write-host "Created Tomcat on " $TOMCAT
Write-host "Give Tomcat 5 seconds to get online"
Start-Sleep -s 5

Write-host "Smoke test"
$URI="http://" + $TOMCAT + ":8080/hello-world/index.jsp" 
curl -Uri $URI > temp
if (Select-String -Pattern "<h1>Hello World!</h1>" temp) {
    Write-host "deployment was successful"
    
} else {
    Write-host "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
}
rm temp