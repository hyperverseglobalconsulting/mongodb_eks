#resource "aws_ebs_volume" "mongodb_volume" {
#  availability_zone = var.ebs_az
#  size              = 20
#  type              = "gp2"
#  tags = {
#    Name = "MongoDB Volume"
#  }
#}

# Creating EBS Volumes
resource "aws_ebs_volume" "mongodb_volume" {
  count = 3

  availability_zone = var.ebs_az
  size              = 5  # Adjusting the size to 5GB as per your requirement.
  type              = "gp2"

  tags = {
    Name = "mongodb_volume_${count.index}"
  }
}

#output "mongodb_volume_id" {
#  description = "The ID of the EBS volume created for MongoDB"
#  value       = aws_ebs_volume.mongodb_volume.id
#}

output "mongodb_volume_ids" {
  description = "The IDs of the EBS volumes created for MongoDB"
  value       = [aws_ebs_volume.mongodb_volume[0].id, aws_ebs_volume.mongodb_volume[1].id, aws_ebs_volume.mongodb_volume[2].id]
}
