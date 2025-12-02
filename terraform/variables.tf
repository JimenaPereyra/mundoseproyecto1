variable "aws_region" {
  type = string
  default = "us-east-1"
}


#variable "dockerhub_username" {
#  type = string
#}

#variable "image_tag" {
#  type = string
#  description = "Tag de la docker image para deploy"
#}

variable "weather_api_key" {
  type = string
  sensitive = true
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID de la imagen Ubuntu 22.04"
  type        = string
  default     = "ami-0c398cb65a93047f2"
}

variable "ssh_public_key" {
  description = "Clave pública para EC2"
  type        = string
}

variable "key_name" {
  description = "Nombre del key pair que se registrará en AWS"
  type        = string
  default     = "proyectofinal"
}

