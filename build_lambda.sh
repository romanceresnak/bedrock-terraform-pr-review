#!/bin/bash

# Script to build Lambda deployment package

set -e

echo "Building Lambda deployment package..."

# Clean up previous builds
rm -f lambda_deployment.zip
rm -rf package/

# Create package directory
mkdir -p package

# Install dependencies
if [ -f lambda_code/requirements.txt ]; then
    echo "Installing dependencies..."
    pip install -r lambda_code/requirements.txt -t package/ --platform manylinux2014_x86_64 --only-binary=:all:
fi

# Copy Lambda function code
echo "Copying Lambda function..."
cp lambda_code/lambda_function.py package/

# Create ZIP file
echo "Creating deployment package..."
cd package
zip -r ../lambda_deployment.zip . -q
cd ..

# Clean up
rm -rf package/

echo "✅ Lambda deployment package created: lambda_deployment.zip"
echo "File size: $(du -h lambda_deployment.zip | cut -f1)"
