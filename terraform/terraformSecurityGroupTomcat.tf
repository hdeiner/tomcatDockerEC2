resource "aws_security_group" "tomcatDockerEC2_tomcat" {
  name = "tomcatDockerEC2_tomcat"
  description = "tomcatDockerEC2 - SSH and Tomcat Access"
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags {
    Name = "tomcatDockerEC2 Tomcat"
  }
}