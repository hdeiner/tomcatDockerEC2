resource "aws_key_pair" "tomcatDockerEC2_key_pair" {
  key_name = "tomcatDockerEC2_key_pair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}