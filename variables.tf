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
