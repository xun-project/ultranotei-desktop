#!/bin/bash

function REPLACE_TOR_CONFIGURE()
{
    echo "Replace configure in TOR"
    sed -i '/^AC_PROG_CC_C99$/s/^/#/' ./tor/configure.ac
    if [ $? -ne 0 ]; then
      echo "/tor/configure.ac no such file or directory"
      return 1
    fi
    sed -i '/#AC_PROG_CC_C99/a #Before autoconf 2.70, AC_PROG_CC_C99 appears to be necessary for some #compilers if you want C99 support.\
#Starting with 2.70, it is obsolete.\
m4_version_prereq([2.70], [:], [AC_PROG_CC_C99])' ./tor/configure.ac
    if [ $? -ne 0 ]; then
      echo "/tor/configure.ac no such file or directory"
      return 1
    fi
    sed -i 's/SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION != 0/defined(SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION) != 0/' ./tor/src/lib/tls/tortls_openssl.c
    if [ $? -ne 0 ]; then
      echo "tor/src/lib/tls/#tortls_openssl.c no such file or directory"
      return 1
    fi
}

UltraNoteInfinity_NAME="UltraNoteInfinity"
UltraNoteInfinity_VERSION="1.0.9"
UltraNoteInfinity_SYSTEM_NAME="amd64"
UltraNoteInfinity_GENERATOR="deb"
UltraNoteInfinity_DEB="$UltraNoteInfinity_NAME-$UltraNoteInfinity_VERSION.$UltraNoteInfinity_SYSTEM_NAME.$UltraNoteInfinity_GENERATOR"
release_folder=build/release

apt update && apt install -y git automake build-essential cmake automake libboost-all-dev libqrencode-dev qttools5-dev qttools5-dev-tools qtdeclarative5-dev qtquickcontrols2-5-dev qtmultimedia5-dev qtwebengine5-dev libqt5webenginewidgets5 libssl-dev libevent-dev qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-dialogs qml-module-qtquick-shapes qml-module-qt-labs-qmlmodels qml-module-qt-labs-platform qml-module-qtwebengine

echo "Update submodules"
git submodule init
git submodule update --remote
if [ $? -ne 0 ]; then
 echo "Subbmodule update filed"
 exit 1
fi

REPLACE_TOR_CONFIGURE
if [ $? -ne 0 ]; then
  echo "TOR configure failed"
  exit 1
fi

mkdir -p $release_folder
chmod -R 755 $release_folder
echo "Build TOR"
./tor_build.sh
if [ $? -ne 0 ]; then
  echo "Failed to run tor_build.sh"
  exit 1
fi
cd $release_folder
echo "Run CMAKE"
cmake -DCMAKE_BUILD_TYPE=Release ../..
if [ $? -ne 0 ]; then
 echo "Failed to run CMAKE"
 exit 1
fi

cd ../..
echo "Run make"
make -j4
if [ $? -ne 0 ]; then
 echo "Failed to run make"
 exit 1
fi

echo "Create deb package"
make package-deb
if [ ! -f "$release_folder/$UltraNoteInfinity_DEB" ]; then
 echo "Failed to create deb package"
 exit 1
fi
dpkg -i "$release_folder/$UltraNoteInfinity_DEB"
echo "Installation successful"
