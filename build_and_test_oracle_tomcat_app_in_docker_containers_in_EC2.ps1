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
$URI="http://" + $TOMCAT + ":8080/passwordAPI/passwordRules/abcde"
curl -Uri $URI > temp
if (Select-String -Pattern @"{"password": "abcde","passwordRules":"password must be at least 8 characters long"}" temp) {
    Write-host "deployment was successful"
    
} else {
    Write-host "DOCKER CREATION/DEPLOYMENT WAS NOT SUCCESSFUL!"
}
rm temp