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

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      
      DEST_DIR="${var.destination_dir}"
      FILENAME="${each.value.filename}"
      URL="${each.value.url}"
      EXPECTED_MD5="${each.value.md5}"
      DEST_FILE="$DEST_DIR/$FILENAME"
      TEMP_FILE="$DEST_DIR/.$FILENAME.tmp.$$"
      LOCK_FILE="$DEST_DIR/.$FILENAME.lock"
      
      mkdir -p "$DEST_DIR"
      
      # If file already exists with correct md5, skip download
      if [ -f "$DEST_FILE" ]; then
        ACTUAL_MD5=$(md5sum "$DEST_FILE" | cut -d' ' -f1)
        if [ "$ACTUAL_MD5" = "$EXPECTED_MD5" ]; then
          echo "File $FILENAME already exists with correct md5, skipping download"
          exit 0
        fi
      fi
      
      # Use flock for atomic locking to prevent concurrent downloads of the same file
      exec 200>"$LOCK_FILE"
      flock -x 200
      
      # Check again after acquiring lock (another process may have downloaded it)
      if [ -f "$DEST_FILE" ]; then
        ACTUAL_MD5=$(md5sum "$DEST_FILE" | cut -d' ' -f1)
        if [ "$ACTUAL_MD5" = "$EXPECTED_MD5" ]; then
          echo "File $FILENAME already exists with correct md5 (checked after lock), skipping download"
          rm -f "$LOCK_FILE"
          exit 0
        fi
      fi
      
      # Download to temporary file
      echo "Downloading $URL to $DEST_FILE"
      curl -fsSL -o "$TEMP_FILE" "$URL"
      
      # Verify md5
      ACTUAL_MD5=$(md5sum "$TEMP_FILE" | cut -d' ' -f1)
      if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
        rm -f "$TEMP_FILE"
        echo "ERROR: MD5 mismatch for $URL. Expected $EXPECTED_MD5, got $ACTUAL_MD5"
        exit 1
      fi
      
      # Atomic rename
      mv "$TEMP_FILE" "$DEST_FILE"
      echo "Successfully downloaded $FILENAME"
      
      # Cleanup lock file
      rm -f "$LOCK_FILE"
    EOT
  }
}
