variable "penpot_database_instances_count" {
  description = "The number of instances in the database cluster."
  type        = number
}

variable "penpot_database_instance_class" {
  description = "The instance class to use for the database."
  type        = string
}

variable "penpot_database_max_capacity" {
  description = "The maximum capacity for the serverless database."
  type        = number
}

variable "penpot_database_min_capacity" {
  description = "The minimum capacity for the serverless database."
  type        = number
}

variable "penpot_database_username" {
  description = "The username to use for the database."
  type        = string
  sensitive   = true
}

variable "penpot_database_password" {
  description = "The password to use for the database."
  type        = string
  sensitive   = true
}
