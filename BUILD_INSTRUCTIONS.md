# Build Instructions for ShutdownController Fix

## Compilation Errors Solution

The compilation errors you're seeing are likely due to:
1. **Cached object files** from previous build
2. **Old header files** in build cache
3. **MSVC compiler** issues with C++11 features

## Steps to Fix

### 1. Clean the Build Directory
```bash
cd c:\github-repos\ultranotei-desktop
rmdir /S /Q build
```

### 2. Rebuild from Scratch
Run the build script again:
```bash
build-win-release.bat
```

### 3. Alternative: Manual CMake Clean & Build
```bash
cd c:\github-repos\ultranotei-desktop
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

## Code Changes Made

### Fixed Issues in ShutdownController

#### Header File (`src/ShutdownController.h`):
- Added missing `checkShutdownComplete()` method declaration
- Removed in-class initialization of `std::atomic<bool>` members (MSVC compatibility)
- All member variables properly declared

#### Implementation File (`src/ShutdownController.cpp`):
- Added constructor initialization list for atomic members
- Fixed member variable initialization
- All methods properly implemented

### Other Modified Files:
- `src/main.cpp` - Updated shutdown sequence
- `src/WalletAdapter.cpp` - Added ShutdownController notification
- `src/NodeAdapter.cpp` - Added ShutdownController notification with timeout

## Verification Steps

After successful build:

1. **Run the application**
2. **Test shutdown** via X button, menu exit, system tray
3. **Check Task Manager** for leftover processes
4. **Verify debug logs** for shutdown progress

## Common MSVC Compiler Issues

### C++11 Atomic Initialization
MSVC can have issues with `std::atomic<bool> var{false};` syntax. Changed to:
- Header: `std::atomic<bool> m_walletClosed;`
- Constructor: `m_walletClosed(false)`

### Signal/Slot Macros
Ensure `Q_OBJECT` macro is present in class declaration (it is).

### Include Dependencies
All necessary includes are present:
- `<QObject>`, `<QTimer>`, `<atomic>`
- `<QDebug>` for logging

## If Errors Persist

### Check File Encoding
Ensure files are saved as UTF-8 without BOM (standard for Qt projects).

### Verify Qt Version
Project uses Qt 5.13.2. Ensure correct version is installed.

### Check CMake Configuration
Verify CMake can find all dependencies:
- Qt5 components (Core, Quick, Widgets, etc.)
- Boost libraries
- OpenSSL

## Expected Output After Fix

Successful build should show:
```
[100%] Built target UltraNoteInfinity
```

Application should:
1. Start normally
2. Shutdown completely when closed
3. Leave no processes running in background
4. Log shutdown progress to debug console

## Testing the Fix

### Manual Test Cases:
- [ ] Close with X button (window close)
- [ ] Close via File → Exit menu
- [ ] Close via system tray icon
- [ ] Close during wallet synchronization
- [ ] Close with Tor enabled

### Verification:
- [ ] No `UltraNoteInfinity.exe` in Task Manager after close
- [ ] No `tor.exe` processes left running
- [ ] Debug log shows shutdown sequence completion

## Support

If issues persist after clean rebuild:
1. Check `build\release\CMakeCache.txt` for configuration issues
2. Verify all source files are in correct encoding
3. Ensure Visual Studio 2022 build tools are installed
4. Check Qt5 installation path in CMake configuration

The ShutdownController implementation follows Qt best practices and should resolve the "wallet keeps running" issue once successfully compiled.
