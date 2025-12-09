# Terraform Download Once

A Terraform module for downloading files atomically with deduplication. Prevents redundant downloads when multiple resources reference the same file.

## Overview

This module downloads a list of files to a destination directory, ensuring:

- **Atomic downloads** - Files are downloaded to a temp file first, then atomically renamed to prevent partial files
- **Deduplication** - Files with the same MD5 hash are downloaded only once, even if specified multiple times
- **Concurrency safety** - Uses `flock` to prevent race conditions when multiple Terraform runs attempt to download the same file
- **MD5 verification** - Downloaded files are verified against their expected MD5 hash

### Use Case

When launching multiple VMs that share a base image (e.g., a qcow2 file named by its MD5 hash), each VM resource might trigger a download if the file doesn't exist. Without coordination, this causes redundant downloads that saturate network bandwidth. This module centralizes file management to download each unique file exactly once.

## Usage

```hcl
module "download_images" {
  source = "path/to/terraform-download-once"

  destination_dir = "/var/lib/images"

  files = [
    {
      url = "https://example.com/images/base.qcow2"
      md5 = "d3b07384d113edec49eaa6238ad5ff00"
    },
    {
      url = "https://example.com/images/base.qcow2"
      md5 = "d3b07384d113edec49eaa6238ad5ff00"  # Duplicate - will only download once
    },
  ]
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `destination_dir` | Directory where files will be downloaded | `string` | Yes |
| `files` | List of files to download with `url` and `md5` | `list(object({url=string, md5=string}))` | No |

## Outputs

| Name | Description |
|------|-------------|
| `downloaded_files` | Map of MD5 to file information (filename, path, url) |
| `destination_dir` | The destination directory |

## Requirements

- Terraform >= 1.0
- `curl` and `flock` available on the system running Terraform

## Development

```bash
make init      # Initialize terraform
make fmt       # Format terraform files
make validate  # Validate configuration
make lint      # Run tflint
make test      # Run tests
make clean     # Clean up test artifacts
```
