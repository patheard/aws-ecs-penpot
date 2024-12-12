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

variable "penpot_google_oauth_client_id" {
  description = "The Google OAuth client ID to use for the database."
  type        = string
  sensitive   = true
}

variable "penpot_google_oauth_client_secret" {
  description = "The Google OAuth client secret to use for the database."
  type        = string
  sensitive   = true
}

variable "penpot_secret_key" {
  description = "The secret key to use for creating persistent user sessions."
  type        = string
  sensitive   = true
}