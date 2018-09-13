This project demomstrates a way to

* Create a local Tomcat 7 (Java 7) server inside a Docker container
* Smoke test the Tomcat server
* Push the verified Docker container to a private Docker registry
* Terraform create an AWS EC2 instance that pulls the private Docker image
* Smoke test the Tomcat Docker instance running in the AWS EC2 instance

Note: The war being deployed in this example is in https://github.com/efsavage/hello-world-war/tree/master/dist
