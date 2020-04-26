set QT_PATH=C:/Qt/5.13.0/msvc2017_64
set OPENSSL_PATH=C:/OpenSSL-Win64/bin
set VC_VARSALL_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build"
set CMAKE_PATH="C:\Program Files\CMake\bin"

rmdir /S /Q  build

mkdir build
cd build
if %errorlevel% neq 0 exit /b %errorlevel%

call %VC_VARSALL_PATH%"\vcvarsall.bat"  x64
if %errorlevel% neq 0 exit /b %errorlevel%

%CMAKE_PATH%"\cmake.exe" .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_PATH%" -DOPENSSL_PATH="%OPENSSL_PATH%" -DPACKMSI=on
if %errorlevel% neq 0 exit /b %errorlevel%

nmake
if %errorlevel% neq 0 exit /b %errorlevel%

nmake package
if %errorlevel% neq 0 exit /b %errorlevel%
