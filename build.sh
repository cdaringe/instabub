#!/bin/bash
# Build script for instabub mod
# Creates a zip file that extracts to an 'instabub' folder

set -e

# Remove old build if it exists
rm -f instabub.zip

# Create zip with the instabub folder
# -r = recursive, -9 = maximum compression
zip -r -9 instabub.zip instabub/

echo "Build complete: instabub.zip"
