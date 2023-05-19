#!/bin/bash

set -e

echo "🚀 Installing DeeplinkTool..."

# Build the Swift package
build_path=$(swift build --disable-sandbox -c release --show-bin-path)
binary_path="$build_path/DeeplinkTool"

# Installation directory
install_directory="/usr/local/bin"
binary_name="DeeplinkTool"

# Prompt the user for the password
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Copy the binary to the installation directory
sudo install "$binary_path" "$install_directory/$binary_name"

echo "✅ DeeplinkTool has been installed to $install_directory/$binary_name"
echo "try running deeplinktool -h"
