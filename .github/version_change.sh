#!/bin/bash
currentVersion=$(cat ../jellyfin.1 | grep " - v" | cut -d "v" -f2)
echo "Current version is v$currentVersion"
echo
echo "Please enter the new version number"
echo "EXAMPLE: '1.4.0'"
read newVersion

sed -i -e "s|v$currentVersion|v$newVersion|g" ../README.md
sed -i -e "s|v$currentVersion|v$newVersion|g" ../jellyman.1
sed -i -e "s|v$currentVersion|v$newVersion|g" ../scripts/jellyman
