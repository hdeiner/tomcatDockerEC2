resource "aws_instance" "ec2_tomcatDockerEC2_tomcat" {
  count = 1
  ami = "ami-759bc50a"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.tomcatDockerEC2_key_pair.key_name}"
  security_groups = ["${aws_security_group.tomcatDockerEC2_tomcat.name}"]
  provisioner "remote-exec" {
    connection {
      type = "ssh",
      user = "ubuntu",
      private_key = "${file("~/.ssh/id_rsa")}"
    }
    script = "terraformProvisionTomcatUsingDocker.sh"
  }
  tags {
    Name = "tomcatDockerEC2 Tomcat ${format("%03d", count.index)}"
  }
}
