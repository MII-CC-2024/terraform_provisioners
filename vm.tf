resource "aws_eip" "server_ip" {}

output "show_server_ip" {
  value = aws_eip.server_ip.public_ip
}

resource "aws_key_pair" "sshkeyt" {
  key_name   = "sshkeyt"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

}

output "show_server_ami" {
  value = data.aws_ami.ubuntu.id
}


resource "aws_instance" "server" {
  ami             = data.aws_ami.ubuntu.id #"ami-053053586808c3e70" #"ami-080e1f13689e07408"
  instance_type   = "t2.nano"
  key_name        = aws_key_pair.sshkeyt.key_name
  security_groups = ["default"]

  tags = {
    Name = "Server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }

  provisioner "local-exec" {
    command = "echo 'The server's IP address is ${self.private_ip}'"
    on_failure = continue
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Destroy-time provisioner'"
  }
  
  provisioner "remote-exec" {
    
    inline = [
      "sudo apt update", "sudo apt install nginx -y", "sudo mv /home/ubuntu/index.html /var/www/html"
    ]
  }


}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.server.id
  allocation_id = aws_eip.server_ip.id
}

