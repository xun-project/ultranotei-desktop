## Building UltraNote Infinity

### On Linux

Dependencies: GCC 4.7.3 or later, CMake 3.9 or later, Boost 1.55 or later, and Qt 5.13 or later.

You may download them from here:

- https://gcc.gnu.org/
- https://www.cmake.org/
- https://www.boost.org/
- https://www.qt.io

or install them using your distribution's package manager.

Debian example:
Installing dependencies:

```
sudo apt-get install build-essential git cmake automake libboost-all-dev libqrencode-dev qt5-default qttools5-dev qttools5-dev-tools qtdeclarative5-dev qtquickcontrols2-5-dev qtmultimedia5-dev qtwebengine5-dev libqt5webenginewidgets5 libssl-dev libevent-dev

```

Clone the source repository with git and build the release version with the following commands:
```
export QTDIR=/home/neo/Qt/5.13.2/gcc_64/
export LD_LIBRARY_PATH=/home/neo/Qt/5.13.2/gcc_64/lib/

OR:
sudo nano .profile
export LD_LIBRARY_PATH="/home/neo/Qt/5.13.2/gcc_64/lib/"
echo $LD_LIBRARY_PATH

mkdir -p build/release
chmod a+x tor_build.sh
./tor_build.sh

cd build/release
cmake -DCMAKE_PREFIX_PATH=$HOME/Qt/5.13.2/gcc_64 -DCMAKE_BUILD_TYPE=Release ../..

cd ../..
make -j4
make package-deb
```

You can find the executable and the DEB package under `build/release`.

[NOTE] you need to find the package provider or compile the required Qt version by yourself on some systems which have no modern Qt versions in their package repositories.

[NOTE] UltraNoteiWallet depends on Qt 5.13-5.14 mostly because of modern QML dependencies. Since current Ubuntu repository Qt versions are low (5.9) the fatest solution is to provide the deb package with a requirement to install Qt libraries manually. After installing the libraries user should launch the shell command to apply the Qt libraries path to LD_LIBRARY_PATH variable on desktop application start:
```
echo "$HOME/Qt/5.13.2/gcc_64/lib" | sudo tee /etc/ld.so.conf.d/qt-mobility.conf && sudo ldconfig -v
```
After the completion of the command user will be able to launch app installed from the *.deb package by clicking on it's icon

### On OSX

Dependencies:


1. Install XCode with Command Line tools from AppStore. Launch it and add your development profile. Make sure you set the proper paths for XCode [Check the XCode documentation]


2. Install QT framework MacOS version 5.13 and above from https://www.qt.io


2. Install Homebrew from https://brew.sh/


3. Install packages via homebrew

```
brew install cmake boost git
```

1. Open project in Qt creator and add "package" to cmake build step properties under the "Projects" tab in Qt Creator main window.

2. Compile the project. 

3. In addition to the executable file it will create the Drag and Drop *.dmg file inside the build directory 

Note that the distributed app will not be signed and users who install it will have to explicitly allow the app to run at first start via `System Preferences > Security & Privacy`.

[NOTE] By 31.12.2019 there is a bug with CPack distrib generation. So the current solution is to build the release version from Qt Creator or command line and then make the DMG file manually with commands:

export QTDIR=/Users/{USERNAME}/Qt/5.14.0/clang_64

export PATH=$QTDIR/bin:$PATH

macdeployqt UltraNoteWallet.app -dmg -qmldir=${FULL_PROJECT_PATH}/src/qml -always-overwrite

[NOTE] Until this [bug](https://gitlab.kitware.com/cmake/cmake/issues/19973) is not resolved by CMake contributor you should manually rename the result *.dmg file to name pattern which contains app version UltraNoteWallet-{VERSION}.dmg where VERSION defined as UN_VERSION inside the UltraNoteWallet.cmake file



### On Windows:

Dependencies:

1. Install Qt framework from https://www.qt.io

    Make sure you have selected:
    
    - OpenSSL component under Tools tree
    
    - QT framework version 5.13 and above for MSVC2017 x64 toolchain
    
2. Install Microsoft Visual Studio 2017 Community edition from https://www.microsoft.com/

    While the installation is in progress make sure you have selected
    
    - Workload: Desktop development with C++
    
    - In the installation bar on the right side make sure "VC++ 2017 ... v141 tools" is selected [NOTE: v141 is matter if you want to use prebuilded Boost binaries]

3. Install Git from https://git-scm.com/download/win

4. Install NSIS from http://nsis.sourceforge.net/Download

5. Install Cmake from https://www.cmake.org/

6. Install Boost prebuilded binaries from https://www.boost.org/ [NOTE it is matter to choose the same version as on VC++ tools installation step [Example: ```v141```] while downloading [[https://sourceforge.net/projects/boost/files/boost-binaries/1.72.0/boost_1_72_0-msvc-14.1-64.exe/download]]

7. OpenSSL 1.1 or later from https://slproweb.com/products/Win32OpenSSL.html

8. MSYS2 from https://www.msys2.org/

Install MSYS2 to your system drive (default path in installer will be C:\msys*)

Then run mingw64.exe console (/folder to MSYS2/, usually C:\msys*) and install dependencies:

```
pacman -S base-devel mingw-w64-x86_64-toolchain mingw-w64-x86_64-openssl mingw-w64-x86_64-libevent mingw-w64-x86_64-zlib
```
One more important step:

```
# Add C:\msys*\usr\bin to your system path
# Add C:\msys*\mingw64\bin to your system path
```

Clone the source code to some path [EXAMPLE: C:\UltraNote\SOURCE\ultranotewallet] and then run "x64 Native Tools Command Prompt for VS 2019" and type the lines below step by step [make sure you have properly replaced the paths for your system]:

```
cd C:\UltraNote\SOURCE\ultranotewallet

set QT_PATH=C:\Qt\5.13.2\msvc2017_64

set CMAKE_PATH=C:\Program Files\CMake\bin
set BOOST_ROOT=C:\local\boost_1_72_0
set BOOSTROOT=C:\local\boost_1_72_0
set BOOST_INCLUDEDIR=C:\local\boost_1_72_0
set BOOST_LIBRARYDIR=C:\local\boost_1_72_0\lib64-msvc-14.1

# Add C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC to your system path.
# Add C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build to your system path.
# Add C:\Program Files\OpenSSL-Win64 to your system path.

# fetch sources
git clone https://bitbucket.org/xunteam/ultranotewallet-infinity.git
cd UltraNoteWallet-infinity
git clone https://bitbucket.org/xunteam/ultranotei-core.git cryptonote
git submodule init
git submodule update

# prepare build

mkdir  build\release\Release

#Now build tor using (MSYS2 Mingw64) shell

#Run:
sh ./tor_build.sh

set OPENSSL_PATH="C:\Qt\Tools\OpenSSL\Win_x64\bin"
set VCINSTALLDIR="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\"
set VC_VARSALL_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build"
set MSVC_REDIST="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Redist\MSVC\14.25.28508\vcredist_x64.exe"
set MSVC_REDIST_DIR="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Redist"

# build wallet using VS2019 developer command prompt

cd build/release

cmake ../.. -G "Visual Studio 16 2019" -D_boost_TEST_VERSIONS=1.72  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_PATH%" -DOPENSSL_PATH="%OPENSSL_PATH%" -DPACKMSI=on

cmake --build . --config Release

```

Now you can collect all binaries and pack it:

```
cd Release
windeployqt UltraNoteInfinity.exe
cd ..
cpack -C Release

```

This will generate the UltraNoteWallet installation package inside the build directory. [Example: ```UltraNoteInfinity-1.0.2-beta-win64.exe```]

NOTE: the Windows packages are not signed by certificate.

Alternatively you can use the Visual Studio GUI for building. To do so, run just the first cmake command from the command list above ["%CMAKE_PATH%"\cmake.exe] with option ```-G "Visual Studio 15 2017 Win64"``` instead of ```-G "NMake Makefiles```", then open the generated file `build/release/UltraNoteInfinity.sln` in Visual Studio. Select build type 'Release' and build the target 'UltraNoteWallet' or for a distribution package build target 'PACKAGE'.

When compiling from Visual Studio you need to add /bigobj switch flag in UltraNoteWallet project, C/C++->Command Line

Good luck!
