# Test configuration for terraform-download-once module

terraform {
  required_version = ">= 1.0"
}

module "download_once" {
  source = "../"

  destination_dir = "${path.module}/downloads"

  files = [
    {
      url = "https://raw.githubusercontent.com/hashicorp/terraform/main/LICENSE"
      md5 = "668a2b90ac703ec2cb16d35919ff28c8"
    },
    # Duplicate entry to test deduplication
    {
      url = "https://raw.githubusercontent.com/hashicorp/terraform/main/LICENSE"
      md5 = "668a2b90ac703ec2cb16d35919ff28c8"
    },
  ]
}

output "downloaded_files" {
  value = module.download_once.downloaded_files
}

output "destination_dir" {
  value = module.download_once.destination_dir
}
