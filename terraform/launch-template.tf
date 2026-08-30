data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = base64encode(
    file("${path.module}/../scripts/user_data.sh")
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}
