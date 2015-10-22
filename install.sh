#!/bin/sh

DOWNLOAD_URI=https://github.com/benoitsan/BBUncrustifyPlugin-Xcode/releases/download/2.1.3/UncrustifyPlugin-2.1.3.zip
PLUGINS_DIR="${HOME}/Library/Application Support/Developer/Shared/Xcode/Plug-ins"

mkdir -p "${PLUGINS_DIR}"
cd "${PLUGINS_DIR}"
curl -SL $DOWNLOAD_URI > UncrustifyPlugin.zip
unzip -oq UncrustifyPlugin.zip
rm UncrustifyPlugin.zip
rm -rf __MACOSX

echo "\nBBUncrustifyPlugin successfuly installed! Please restart your Xcode."
