#!/bin/bash
module load imagemagick/7.1.1-8-rocky8_x64-ncf
SUB=$1
BASE=$2
Ein=$3
# Directory containing the original images
SOURCE_DIR="${BASE}/${SUB}/${Ein}/report/efield_figures"

# Directory where modified images will be saved
DEST_DIR="${SOURCE_DIR}/trimmed"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Loop through all image files in the source directory
for img in "${SOURCE_DIR}"/*.png; do
  # Extract the filename from the path
  filename=$(basename "$img")

    # Construct the destination path for the trimmed image
    dest="${DEST_DIR}/${filename}"

    # Use ImageMagick to trim the image and save it to the destination directory
    convert "$img" -trim +repage -transparent white "$dest"

    #remove the untrimmed image
   rm "$img"
done

echo "All images have been processed and saved to ${DEST_DIR}."
