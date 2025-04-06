#!/bin/bash

# Script to prepare a new release of vllm-serve-cli

set -e

# Check if version is provided
if [ -z "$1" ]; then
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 0.2.0"
    exit 1
fi

VERSION=$1

# Update version in files
echo "Updating version to $VERSION..."
sed -i "s/__version__ = \".*\"/__version__ = \"$VERSION\"/" vllm_serve_cli/__init__.py
sed -i "s/version = \".*\"/version = \"$VERSION\"/" pyproject.toml
sed -i "s/version=\".*\"/version=\"$VERSION\"/" setup.py

# Build the distribution
echo "Building distribution..."
python -m build

# Verify files
echo "Generated files:"
ls -l dist/

echo ""
echo "Done! To publish this release:"
echo "1. Commit the version changes"
echo "   git add vllm_serve_cli/__init__.py pyproject.toml setup.py"
echo "   git commit -m \"Bump version to $VERSION\""
echo ""
echo "2. Create a tag"
echo "   git tag v$VERSION"
echo "   git push origin v$VERSION"
echo ""
echo "3. Upload to PyPI"
echo "   twine upload dist/*"
echo ""
echo "Or create a GitHub release and let the workflow do it for you." 