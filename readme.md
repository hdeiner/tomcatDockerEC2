This project demomstrates a way to

* Create a local Tomcat 7 (Java 7) server inside a Docker container
* Smoke test the Tomcat server
* Push the verified Docker container to a private Docker registry
* Terraform create an AWS EC2 instance that pulls the private Docker image
* Smoke test the Tomcat Docker instance running in the AWS EC2 instance

Note: The war being deployed in this example is in https://github.com/efsavage/hello-world-war/tree/master/dist

Important: This project will require the installation of Docker, AWS-CLI, and Terraform.  It also requires that the user has sucessfully set up their ~/ssh settings (id_rsa, id_rsa.pub, and a pem file to work with AWS: HowardDeiner.pem in this example).  Furthermore, the .aws directory will need config and credentials, setup for AWS to work. 

Warning: Visual Studio will convert the \n to \r\n line ending characters ("Windows" vs "Unix" line handling).  This will cause the Terraform remote-provisioner to fail, as the style of the terraformProvisionTomcatUsingDocker.sh file is run in the Linux environment of the AWS instance.  I used Sublime Text to fix the lines before I ran terraform.  Be careful to not check in a changed and corrupted provisioning script.
