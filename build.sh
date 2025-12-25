#!/bin/bash
# Simple build script for Cloudflare Pages
# It prepares the 'dist' directory with our static data

# Clean/Create dist directory
rm -rf dist
mkdir -p dist

# Copy data folder contents to dist
# We copy contents so accessible at root e.g. /M31.json instead of /data/M31.json
# OR keep structure. User said "base URL like https://data.my-astro-app.com/M31.json".
# If I copy data/* to dist/, then dist/M31.json -> root/M31.json. Correct.

cp -r data/* dist/

echo "Build complete. Contents of dist:"
ls -F dist/
