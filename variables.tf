variable "image_name" {
  type = string
}
variable "container_command" {
  type    = list(string)
  default = null
}
variable "container_environment" {
  type = list
  default = []
}
variable "subnets" {
  type = list(string)
}