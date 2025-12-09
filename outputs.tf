output "downloaded_files" {
  description = "Map of md5 to downloaded file information"
  value = {
    for md5, file in local.files_to_download : md5 => {
      filename = file.filename
      path     = "${var.destination_dir}/${file.filename}"
      url      = file.url
    }
  }
}

output "destination_dir" {
  description = "The destination directory where files are downloaded"
  value       = var.destination_dir
}
