# Create a map of unique files by md5 to avoid duplicate downloads
locals {
  # Extract unique files by md5 hash
  unique_files = {
    for file in var.files : file.md5 => file...
  }

  # Build the final map with url and destination filename
  # Extract extension from the last path segment of the URL
  files_to_download = {
    for md5, files in local.unique_files : md5 => {
      url       = files[0].url
      md5       = md5
      extension = try(regex("\\.[^./]+$", element(split("/", files[0].url), length(split("/", files[0].url)) - 1)), "")
      filename  = "${md5}${try(regex("\\.[^./]+$", element(split("/", files[0].url), length(split("/", files[0].url)) - 1)), "")}"
    }
  }
}

# Download each unique file atomically
resource "terraform_data" "download" {
  for_each = local.files_to_download

  triggers_replace = {
    md5             = each.value.md5
    destination_dir = var.destination_dir
    filename        = each.value.filename
  }

  connection {
    type                = "ssh"
    host                = var.ssh_host
    user                = var.ssh_user
    private_key         = var.ssh_private_key
    certificate         = var.ssh_certificate
    port                = var.ssh_port
    bastion_host        = var.ssh_bastion_host
    bastion_user        = var.ssh_bastion_user
    bastion_private_key = var.ssh_bastion_private_key
    bastion_certificate = var.ssh_bastion_certificate
    bastion_port        = var.ssh_bastion_port
  }

  provisioner "remote-exec" {
    inline = [
      "set -euo pipefail",
      "DEST_DIR='${var.destination_dir}'",
      "FILENAME='${each.value.filename}'",
      "URL='${each.value.url}'",
      "EXPECTED_MD5='${each.value.md5}'",
      "DEST_FILE=\"$DEST_DIR/$FILENAME\"",
      "TEMP_FILE=\"$DEST_DIR/.$FILENAME.tmp.$$\"",
      "LOCK_FILE=\"$DEST_DIR/.$FILENAME.lock\"",
      "mkdir -p \"$DEST_DIR\"",
      "if [ -f \"$DEST_FILE\" ]; then ACTUAL_MD5=$(md5sum \"$DEST_FILE\" | cut -d' ' -f1); if [ \"$ACTUAL_MD5\" = \"$EXPECTED_MD5\" ]; then echo \"File $FILENAME already exists with correct md5, skipping download\"; exit 0; fi; fi",
      "exec 200>\"$LOCK_FILE\"",
      "flock -x 200",
      "if [ -f \"$DEST_FILE\" ]; then ACTUAL_MD5=$(md5sum \"$DEST_FILE\" | cut -d' ' -f1); if [ \"$ACTUAL_MD5\" = \"$EXPECTED_MD5\" ]; then echo \"File $FILENAME already exists with correct md5 (checked after lock), skipping download\"; rm -f \"$LOCK_FILE\"; exit 0; fi; fi",
      "echo \"Downloading $URL to $DEST_FILE\"",
      "curl -fsSL -o \"$TEMP_FILE\" \"$URL\"",
      "ACTUAL_MD5=$(md5sum \"$TEMP_FILE\" | cut -d' ' -f1)",
      "if [ \"$ACTUAL_MD5\" != \"$EXPECTED_MD5\" ]; then rm -f \"$TEMP_FILE\"; echo \"ERROR: MD5 mismatch for $URL. Expected $EXPECTED_MD5, got $ACTUAL_MD5\"; exit 1; fi",
      "mv \"$TEMP_FILE\" \"$DEST_FILE\"",
      "echo \"Successfully downloaded $FILENAME\"",
      "rm -f \"$LOCK_FILE\""
    ]
  }
}
