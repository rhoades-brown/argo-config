variable "input1" {
  type = number
}

variable "input2" {
  type = number
}

output "output1" {
  value = sum([var.input1, var.input2])
}