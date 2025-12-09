set QT_PATH=C:/Qt/Qt5.13.2/5.13.2/msvc2017_64
set OPENSSL_PATH=C:/Program Files/OpenSSL-Win64/bin
set VC_VARSALL_PATH="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
set CMAKE_PATH=C:\Program Files\CMake\bin

rmdir /S /Q build

REM Create build directories
mkdir build\release
mkdir build\release\Release
mkdir build\release\Release\release

REM Copy Tor files
echo Copying Tor files...
xcopy /E /I /Y "C:\tor" "build\release\Release"
copy /Y "C:\tor\bin\tor.exe" "build\release\Release\release\tor.exe"

echo Copying OpenSSL DLLs...
copy /Y "%OPENSSL_PATH%\libcrypto-1_1-x64.dll" "build\release\Release\"
copy /Y "%OPENSSL_PATH%\libssl-1_1-x64.dll" "build\release\Release\"


cd build\release

call %VC_VARSALL_PATH%"\vcvarsall.bat" x64
if %errorlevel% neq 0 exit /b %errorlevel%

"%CMAKE_PATH%\cmake.exe" ../.. -G "Visual Studio 17 2022" -D_boost_TEST_VERSIONS=1.65.1 -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_PATH%" -DOPENSSL_PATH="%OPENSSL_PATH%" -DPACKMSI=on
if %errorlevel% neq 0 exit /b %errorlevel%

"%CMAKE_PATH%\cmake.exe" --build . --config Release
if %errorlevel% neq 0 exit /b %errorlevel%

"%CMAKE_PATH%\cpack.exe" -C Release
if %errorlevel% neq 0 exit /b %errorlevel%
