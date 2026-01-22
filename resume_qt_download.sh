#!/bin/bash
echo "Resuming Qt 5.14.2 download..."
curl -C - -O https://download.qt.io/archive/qt/5.14/5.14.2/qt-opensource-mac-x64-5.14.2.dmg

echo ""
echo "Download complete or interrupted."
echo "Please verify the file size is approximately 2.7GB."
echo ""
echo "Installation Instructions:"
echo "1. Open 'qt-opensource-mac-x64-5.14.2.dmg'"
echo "2. Run the installer application."
echo "3. Log in or skip login (if allowed)."
echo "4. Select components: Qt 5.14.2 (mandatory). Recommended: Qt WebEngine, Qt Script if available."
echo "5. After installation, update your environment variables as per README (see install_qt_env.sh in this folder if I created one, otherwise check README)."
