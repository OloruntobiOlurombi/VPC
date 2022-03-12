resource "aws_launch_configuration" "web_instances" { #aws_instance
  name_prefix = "web_instances-"
  image_id           = "ami-04505e74c0741db8d" #ami 
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.qdb_ec2_profile.name}"

 # tags = {Name = "Welcometoqdb"}
  security_groups = ["${aws_security_group.Webserver_Apache_SG.id}"]
  # subnet_id = ["${aws_subnet.public.id}"]
  user_data = <<-EOF
  #!/bin/sh
  sudo apt-get update
  sudo apt install -y apache2
  sudo systemctl status apache2 
  sudo systemctl start apache2 
  sudo chown -R $USER:$USER /var/www/html
  sudo echo "<html><body><h1>Hello from Webserver at instance id `curl http://169.254.169.254/latest/meta-data/instance-id` </h1></body></html>" > /var/www/html/index.html
  EOF

   lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "web" {
  ami           =  "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private.id
  user_data = <<-EOF
  #!/bin/sh
  sudo apt-get update
  sudo apt install -y apache2
  sudo systemctl status apache2 
  sudo systemctl start apache2 
  sudo chown -R $USER:$USER /var/www/html
  sudo echo "<html><body><h1>Hello from Webserver at instance id `curl http://169.254.169.254/latest/meta-data/instance-id` </h1></body></html>" > /var/www/html/index.html
  EOF
  tags = {
    Name = "HelloWorld"
  }
}

