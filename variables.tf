variable "files" {
  description = "List of files to download. Each file has a url and expected md5 hash."
  type = list(object({
    url = string
    md5 = string
  }))
  default = []
}

variable "destination_dir" {
  description = "Directory where files will be downloaded. Files are named <md5>.<extension from url>"
  type        = string
}

variable "ssh_host" {
  description = "The hostname or IP address of the remote server"
  type        = string
}

variable "ssh_user" {
  description = "The SSH username for connecting to the remote server"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "The private SSH key for authentication (content, not path)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_private_key_file" {
  description = "Path to the private SSH key file for authentication"
  type        = string
  default     = null
}

variable "ssh_certificate" {
  description = "The SSH certificate for authentication (content, not path). Used with ssh_private_key."
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_port" {
  description = "The SSH port on the remote server"
  type        = number
  default     = 22
}

variable "ssh_bastion_host" {
  description = "The hostname or IP of a bastion/jump host (optional)"
  type        = string
  default     = null
}

variable "ssh_bastion_user" {
  description = "The SSH username for the bastion host"
  type        = string
  default     = null
}

variable "ssh_bastion_private_key" {
  description = "The private SSH key for bastion authentication (content, not path)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_bastion_certificate" {
  description = "The SSH certificate for bastion authentication (content, not path). Used with ssh_bastion_private_key."
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_bastion_port" {
  description = "The SSH port on the bastion host"
  type        = number
  default     = 22
}
