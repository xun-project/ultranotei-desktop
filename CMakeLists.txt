# UltraNote CMakeList.txt
#
# Usage:
#    cd build/release
#    cmake -DCMAKE_BUILD_TYPE=Release ../..
#    make -j4
#
# Use specific QT5 version or non-standard Qt5 path
#    cmake -DCMAKE_BUILD_TYPE=Release -DQT5_ROOT_PATH=~/Qt/5.10.0/clang_64/
#

# some Qt5 features require a newer cmake
cmake_minimum_required(VERSION 3.9)

# Cmake policies
# silence AUTO_MOC warnings
if (POLICY CMP0071)
  cmake_policy(SET CMP0071 NEW)
endif ()

# Fix behavior of CMAKE_CXX_STANDARD when targeting macOS.
if (POLICY CMP0025)
  cmake_policy(SET CMP0025 NEW)
endif ()

# Require C++11 standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

# load common definitions
include(UltraNoteWallet.cmake)
project(${UN_PROJECT_NAME} C CXX)

# One shouldn't generate the BUILD project directly in the SOURCES folder!
if ( ${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR} )
  if ( NOT SAME_BUILD_AND_SOURCE_FOLDER_WARNING_ALREADY_ISSUED )
    message(FATAL_ERROR "It is not advised to BUILD the binaries directly in the SOURCE folder!\n If you want to proceed with this option, just run cmake once again" )
    set( SAME_BUILD_AND_SOURCE_FOLDER_WARNING_ALREADY_ISSUED TRUE )
  endif()
endif()

# pull version from Git tag and revision
find_package(Git)
if(GIT_FOUND)
  exec_program(
    ${GIT_EXECUTABLE}
    ${CMAKE_CURRENT_SOURCE_DIR}
    ARGS "rev-parse --is-inside-work-tree"
    OUTPUT_VARIABLE GITWORKTREE )
  if( "${GITWORKTREE}" STREQUAL "true" )
    exec_program(
      ${GIT_EXECUTABLE}
      ${CMAKE_CURRENT_SOURCE_DIR}
      ARGS "name-rev --tags --name-only $(git rev-parse HEAD)"
      OUTPUT_VARIABLE GITTAG )
    exec_program(
      ${GIT_EXECUTABLE}
      ${CMAKE_CURRENT_SOURCE_DIR}
      ARGS "rev-parse --short HEAD"
      OUTPUT_VARIABLE GITHASH )
    exec_program(
      ${GIT_EXECUTABLE}
      ${CMAKE_CURRENT_SOURCE_DIR}
      ARGS "diff-index --name-only HEAD"
      OUTPUT_VARIABLE GITDIRTY
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(GITDIRTY)
      set (UltraNote_VERSION "${GITTAG}")
      set (UltraNote_GITREV "${GITHASH}-dirty")
    else()
      set (UltraNote_VERSION  "${GITTAG}")
      set (UltraNote_GITREV "${GITHASH}")
    endif()
  endif()
endif()

if ("${UltraNote_VERSION}" STREQUAL "undefined" OR NOT "${UltraNote_VERSION}")
  set (UltraNote_VERSION "${UN_VERSION}")
endif ()

string(TIMESTAMP UltraNote_BUILDTIME UTC)

message( STATUS "Building ${PROJECT_NAME} ${UltraNote_VERSION} ${UltraNote_GITREV} ${UltraNote_BUILDTIME}")

# Note: cryponote expects GIT revision in VERSION variable
set(VERSION "${UltraNote_VERSION}")
set(CN_CURRENCY_DISPLAY_NAME ${UN_CURRENCY_DISPLAY_NAME})
set(CN_CURRENCY_TICKER ${UN_CURRENCY_TICKER})
configure_file("cryptonote/src/version.h.in" "version.h")
configure_file("src/CryptoNoteWalletConfig.h.in" "CryptoNoteWalletConfig.h")

# export for C compiler
add_definitions(-DVERSION=\"${UltraNote_VERSION}\")
add_definitions(-DGIT_REVISION=\"${UltraNote_GITREV}\")

# ---------------------------------------------------------------------
# Collect Build Dependencies
#

# Find Boost
set(Boost_USE_STATIC_LIBS ON)
Set(Boost_NO_BOOST_CMAKE ON)
if(WIN32)
  set(Boost_USE_STATIC_RUNTIME OFF)
else(WIN32)
  set(Boost_USE_STATIC_RUNTIME ON)
endif(WIN32)

find_package(Boost 1.55 COMPONENTS date_time filesystem program_options regex serialization system thread chrono REQUIRED)
if ((${Boost_MAJOR_VERSION} EQUAL 1) AND (${Boost_MINOR_VERSION} EQUAL 54))
  message(SEND_ERROR "Boost version 1.54 is unsupported, more details are available here http://goo.gl/RrCFmA")
endif ()

include_directories(${Boost_INCLUDE_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

# Find Qt5
# Set up a list of common QT installation paths, i.e.
#  "~/Qt/5.10.0/clang_64/"
#  "C:\\Qt\\Qt5.6.0\\5.6\\msvc2013_64\\"
set( QT5_ROOT_PATH CACHE PATH "Qt5 root directory (i.e. where the 'bin' folder lies)" )
if ( QT5_ROOT_PATH )
  list( APPEND CMAKE_PREFIX_PATH ${QT5_ROOT_PATH} )
endif()

# in the case no Qt5Config.cmake file could be found, cmake will explicitly ask the user for the QT5_DIR containing it!
# thus no need to keep additional variables and checks

find_package(Qt5 5.13 COMPONENTS Core Quick QuickControls2 Gui Widgets Network Multimedia WebEngine WebEngineWidgets Qml REQUIRED)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOUIC_SEARCH_PATHS "src/gui/ui")

# set QT5_ROOT_PATH if it wasn't set by the user
if ( NOT QT5_ROOT_PATH )
  get_target_property(QT5_LIB_LOCATION Qt5::Core LOCATION_${CMAKE_BUILD_TYPE})
  get_filename_component(QT5_LIB_LOCATION ${QT5_LIB_LOCATION} DIRECTORY)
  get_filename_component(QT5_ROOT_PATH ${QT5_LIB_LOCATION} DIRECTORY)
endif ()

# ---------------------------------------------------------------------
# Add UltraNote Sources
#

# QML Imports
list(APPEND QML_DIRS ${CMAKE_SOURCE_DIR}/src/qml/)
set(QML_IMPORT_PATH "${QML_DIRS}" CACHE STRING "QML Modules Paths" FORCE)
set(QML2_IMPORT_PATH "${QML_DIRS}" CACHE STRING "QML Modules Paths" FORCE)

# Add libqrencode
include(QREncode.cmake)

# UltraNote Core Library
set(CRYPTONOTE_LIB cryptonote)
set(CRYPTONOTE_SOURCES
  cryptonote/external/miniupnpc/connecthostport.c
  cryptonote/external/miniupnpc/igd_desc_parse.c
  cryptonote/external/miniupnpc/minisoap.c
  cryptonote/external/miniupnpc/miniupnpc.c
  cryptonote/external/miniupnpc/miniwget.c
  cryptonote/external/miniupnpc/minixml.c
  cryptonote/external/miniupnpc/portlistingparse.c
  cryptonote/external/miniupnpc/receivedata.c
  cryptonote/external/miniupnpc/upnpcommands.c
  cryptonote/external/miniupnpc/upnpreplyparse.c
  cryptonote/src/Common/Base58.cpp
  cryptonote/src/Common/CommandLine.cpp
  cryptonote/src/Common/Util.cpp
  cryptonote/src/Common/StringTools.cpp
  cryptonote/src/Common/JsonValue.cpp
  cryptonote/src/Common/ConsoleTools.cpp
  cryptonote/src/Common/MemoryInputStream.cpp
  cryptonote/src/Common/PathTools.cpp
  cryptonote/src/Common/StdInputStream.cpp
  cryptonote/src/Common/StdOutputStream.cpp
  cryptonote/src/Common/StreamTools.cpp
  cryptonote/src/Common/StringOutputStream.cpp
  cryptonote/src/Common/StringView.cpp
  cryptonote/src/Common/VectorOutputStream.cpp
  cryptonote/src/crypto/blake256.c
  cryptonote/src/crypto/chacha.c
  cryptonote/src/crypto/crypto-ops-data.c
  cryptonote/src/crypto/crypto-ops.c
  cryptonote/src/crypto/crypto.cpp
  cryptonote/src/crypto/groestl.c
  cryptonote/src/crypto/hash-extra-blake.c
  cryptonote/src/crypto/hash-extra-groestl.c
  cryptonote/src/crypto/hash-extra-jh.c
  cryptonote/src/crypto/hash-extra-skein.c
  cryptonote/src/crypto/hash.c
  cryptonote/src/crypto/jh.c
  cryptonote/src/crypto/keccak.c
  cryptonote/src/crypto/oaes_lib.c
  cryptonote/src/crypto/random.c
  cryptonote/src/crypto/skein.c
  cryptonote/src/crypto/slow-hash.c
  cryptonote/src/crypto/slow-hash.cpp
  cryptonote/src/crypto/tree-hash.c
  cryptonote/src/CryptoNoteCore/BlockchainIndices.cpp
  cryptonote/src/CryptoNoteCore/BlockchainMessages.cpp
  cryptonote/src/CryptoNoteCore/BlockIndex.cpp
  cryptonote/src/CryptoNoteCore/CoreConfig.cpp
  cryptonote/src/CryptoNoteCore/CryptoNoteBasic.cpp
  cryptonote/src/CryptoNoteCore/CryptoNoteTools.cpp
  cryptonote/src/CryptoNoteCore/Currency.cpp
  cryptonote/src/CryptoNoteCore/DepositIndex.cpp
  cryptonote/src/CryptoNoteCore/MinerConfig.cpp
  cryptonote/src/CryptoNoteCore/Transaction.cpp
  cryptonote/src/CryptoNoteCore/Account.cpp
  cryptonote/src/CryptoNoteCore/Blockchain.cpp
  cryptonote/src/CryptoNoteCore/Checkpoints.cpp
  cryptonote/src/CryptoNoteCore/CryptoNoteBasicImpl.cpp
  cryptonote/src/CryptoNoteCore/Core.cpp
  cryptonote/src/CryptoNoteCore/CryptoNoteFormatUtils.cpp
  cryptonote/src/CryptoNoteCore/CryptoNoteSerialization.cpp
  cryptonote/src/CryptoNoteCore/Difficulty.cpp
  cryptonote/src/CryptoNoteCore/IBlock.cpp
  cryptonote/src/CryptoNoteCore/Miner.cpp
  cryptonote/src/CryptoNoteCore/TransactionExtra.cpp
  cryptonote/src/CryptoNoteCore/TransactionPool.cpp
  cryptonote/src/CryptoNoteCore/TransactionPrefixImpl.cpp
  cryptonote/src/CryptoNoteCore/TransactionUtils.cpp
  cryptonote/src/InProcessNode/InProcessNode.cpp
  cryptonote/src/InProcessNode/InProcessNodeErrors.cpp
  cryptonote/src/NodeRpcProxy/NodeErrors.cpp
  cryptonote/src/NodeRpcProxy/NodeRpcProxy.cpp
  cryptonote/src/P2p/NetNodeConfig.cpp
  cryptonote/src/Serialization/BinaryInputStreamSerializer.cpp
  cryptonote/src/Serialization/BinaryOutputStreamSerializer.cpp
  cryptonote/src/Serialization/JsonInputValueSerializer.cpp
  cryptonote/src/Serialization/JsonOutputStreamSerializer.cpp
  cryptonote/src/Serialization/KVBinaryInputStreamSerializer.cpp
  cryptonote/src/Serialization/KVBinaryOutputStreamSerializer.cpp
  cryptonote/src/Serialization/SerializationOverloads.cpp
  cryptonote/src/Transfers/BlockchainSynchronizer.cpp
  cryptonote/src/Transfers/SynchronizationState.cpp
  cryptonote/src/Transfers/TransfersConsumer.cpp
  cryptonote/src/Transfers/TransfersContainer.cpp
  cryptonote/src/Transfers/TransfersSubscription.cpp
  cryptonote/src/Transfers/TransfersSynchronizer.cpp
  cryptonote/src/Wallet/LegacyKeysImporter.cpp
  cryptonote/src/Wallet/WalletAsyncContextCounter.cpp
  cryptonote/src/Wallet/WalletErrors.cpp
  cryptonote/src/WalletLegacy/KeysStorage.cpp
  cryptonote/src/WalletLegacy/WalletLegacy.cpp
  cryptonote/src/WalletLegacy/WalletHelper.cpp
  cryptonote/src/WalletLegacy/WalletLegacySerializer.cpp
  cryptonote/src/WalletLegacy/WalletLegacySerialization.cpp
  cryptonote/src/WalletLegacy/WalletTransactionSender.cpp
  cryptonote/src/WalletLegacy/WalletUnconfirmedTransactions.cpp
  cryptonote/src/WalletLegacy/WalletUserTransactionsCache.cpp
  cryptonote/src/System/ContextGroup.cpp
  cryptonote/src/System/Event.cpp
  cryptonote/src/System/EventLock.cpp
  cryptonote/src/System/InterruptedException.cpp
  cryptonote/src/System/Ipv4Address.cpp
  cryptonote/src/System/TcpStream.cpp
  cryptonote/src/HTTP/HttpRequest.cpp
  cryptonote/src/HTTP/HttpParser.cpp
  cryptonote/src/HTTP/HttpParserErrorCodes.cpp
  cryptonote/src/HTTP/HttpResponse.cpp
  cryptonote/src/Rpc/HttpClient.cpp
  cryptonote/src/Rpc/JsonRpc.cpp
  cryptonote/src/P2p/NetNode.cpp
  cryptonote/src/P2p/LevinProtocol.cpp
  cryptonote/src/P2p/NetNodeConfig.cpp
  cryptonote/src/P2p/PeerListManager.cpp
  cryptonote/src/CryptoNoteProtocol/CryptoNoteProtocolHandler.cpp
  cryptonote/src/Logging/ILogger.cpp
  cryptonote/src/Logging/LoggerGroup.cpp
  cryptonote/src/Logging/CommonLogger.cpp
  cryptonote/src/Logging/LoggerManager.cpp
  cryptonote/src/Logging/FileLogger.cpp
  cryptonote/src/Logging/StreamLogger.cpp
  cryptonote/src/Logging/ConsoleLogger.cpp
  cryptonote/src/Logging/LoggerMessage.cpp
  cryptonote/src/Logging/LoggerRef.cpp
  cryptonote/src/BlockchainExplorer/BlockchainExplorer.cpp
  cryptonote/src/BlockchainExplorer/BlockchainExplorerDataBuilder.cpp
  cryptonote/src/BlockchainExplorer/BlockchainExplorerErrors.cpp
)

include_directories(BEFORE ${CMAKE_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  src
  cryptonote/external
  cryptonote/include
  cryptonote/src
)

file(GLOB_RECURSE SOURCES src/*.cpp)
file(GLOB_RECURSE HEADERS src/*.h src/*.hpp)
set(QRC src/resources.qrc)

# Detect Build Platform
#
if (WIN32)
  if (NOT MSVC)
    message(FATAL_ERROR "Only MSVC is supported on this platform")
  endif ()
  add_definitions(/D_CRT_SECURE_NO_WARNINGS /D_WIN32_WINNT=0x0600 /DSTATICLIB)
  include_directories(cryptonote/src/platform/msc)

  set(PLATFORM_DIR Windows)
  set(BUILD_PLATFORM WIN32)
  set(BUILD_RESOURCES src/cryptonotewallet.rc)
  set(QTMAIN Qt5::WinMain)

elseif (UNIX)
  set(CRYPTONOTE_SOURCES ${CRYPTONOTE_SOURCES} cryptonote/external/miniupnpc/minissdpc.c)
  if (APPLE)
    set(PLATFORM_DIR OSX)
    set(BUILD_PLATFORM MACOSX_BUNDLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.10)
    set(MACOSX_BUNDLE_GUI_IDENTIFIER ${UN_IDENTIFIER})
    set(MACOSX_BUNDLE_INFO_STRING ${UN_SUMMARY})
    set(MACOSX_BUNDLE_BUNDLE_NAME ${PROJECT_NAME})
    set(MACOSX_BUNDLE_LONG_VERSION_STRING  "Version ${UltraNote_VERSION}-${UltraNote_GITREV}")
    set(MACOSX_BUNDLE_SHORT_VERSION_STRING "${UltraNote_VERSION}")
    set(MACOSX_BUNDLE_BUNDLE_VERSION "${UltraNote_VERSION}")
    set(MACOSX_BUNDLE_COPYRIGHT "${UN_COPYRIGHT}")

    enable_language(ASM)
    include_directories(/usr/include/malloc)
    file(GLOB_RECURSE OBJC_SOURCES src/*.mm)
    set(SOURCES ${SOURCES} ${OBJC_SOURCES})
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -maes -D_DARWIN_C_SOURCE")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework Cocoa -framework OpenGL -framework CoreFoundation -framework Carbon -framework IOKit -L/usr/lib")

    set(MACOSX_BUNDLE_ICON_FILE UltraNoteLogo.icns)
    set(APPLICATION_ICON src/images/UltraNoteLogo.icns)
    set_source_files_properties(${APPLICATION_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    set(BUILD_RESOURCES ${APPLICATION_ICON})

  else(APPLE)
    set(PLATFORM_DIR Linux)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -maes")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -maes")
  endif (APPLE)
endif ()

# Build CryptoNote library
include_directories(cryptonote/src/Platform/${PLATFORM_DIR})
file(GLOB PLATFORM_SOURCES cryptonote/src/Platform/${PLATFORM_DIR}/System/*)
set(CRYPTONOTE_SOURCES ${CRYPTONOTE_SOURCES} ${PLATFORM_SOURCES})
add_library(${CRYPTONOTE_LIB} STATIC ${CRYPTONOTE_SOURCES})
set_target_properties(${CRYPTONOTE_LIB} PROPERTIES COMPILE_DEFINITIONS _GNU_SOURCE)
target_link_libraries(${CRYPTONOTE_LIB} ${Boost_LIBRARIES})

# zlib
add_subdirectory(zlib EXCLUDE_FROM_ALL)

# Build UltraNote app
add_executable(${PROJECT_NAME} ${BUILD_PLATFORM} ${BUILD_RESOURCES} ${SOURCES} ${HEADERS} ${QRC})
set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_DEFINITIONS _GNU_SOURCE)
target_link_libraries(${PROJECT_NAME} ${Boost_LIBRARIES} ${QTMAIN} zlibstatic ${CRYPTONOTE_LIB} ${QRENCODE_LIB} Qt5::Gui Qt5::Quick Qt5::QuickControls2 Qt5::Widgets Qt5::Network Qt5::Multimedia Qt5::WebEngine Qt5::WebEngineWidgets Qt5::Qml)

# Platform-dependent properties
if (APPLE)
  set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/contrib/macos/MacOSXBundleInfo.plist.in")
elseif (UNIX)
  target_link_libraries(${PROJECT_NAME} -lpthread)
elseif (WIN32)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj")
  target_link_libraries(${PROJECT_NAME} Imm32 Iphlpapi Winmm)
endif (APPLE)

# ---------------------------------------------------------------
# Installation
#
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VERSION ${UltraNote_VERSION})
set(CPACK_PACKAGE_VENDOR ${UN_VENDOR})
set(CPACK_PACKAGE_CONTACT ${UN_CONTACT})
set(CPACK_PACKAGE_DESCRIPTION ${UN_DESCRIPTION})
set(CPACK_STRIP_FILES ON)
if (APPLE)
  set(CPACK_GENERATOR DragNDrop)
  set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")
  find_program(MACDEPLOYQT macdeployqt PATHS ${QT5_ROOT_PATH}/bin/)

  # Run Qt5 Packager for MacOS Bundles
  install(CODE "execute_process( COMMAND \"${MACDEPLOYQT}\" \"${PROJECT_NAME}.app\")" COMPONENT Runtime)
  install(TARGETS ${PROJECT_NAME} BUNDLE DESTINATION . COMPONENT Runtime)
  install(PROGRAMS build/release/tor/bin/tor DESTINATION . COMPONENT Runtime)

elseif (UNIX)
  install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
  install(FILES src/ultranotewallet.desktop DESTINATION share/applications)
  install(FILES src/images/UltraNoteLogo.png DESTINATION share/pixmaps RENAME ultranote.png)
  install(FILES COPYING DESTINATION share/doc/ultranotewallet)
  install(PROGRAMS build/release/tor/bin/tor DESTINATION bin)

	SET(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
	SET(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
	SET(CPACK_PACKAGE_ICON src/images/UltraNoteLogo.png)

  if (NOT PACKRPM)
    set(CPACK_GENERATOR DEB)
    set(CPACK_DEBIAN_PACKAGE_NAME ${CPACK_PACKAGE_NAME})
    set(CPACK_SYSTEM_NAME amd64)
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR} <xrydev@gmail.com>")
    set(CPACK_DEBIAN_PACKAGE_SECTION Office)
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
    set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "${UN_DESCRIPTION}")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_DEBIAN_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.${CPACK_SYSTEM_NAME}")
	else ()
    set(CPACK_GENERATOR RPM)
    set(CPACK_SYSTEM_NAME x86_64)
    #set(CPACK_RPM_PACKAGE_RELEASE ${VERSION_RELEASE})
    set(CPACK_RPM_PACKAGE_LICENSE "GPL3")
    set(CPACK_RPM_PACKAGE_GROUP Office)
    set(CPACK_RPM_PACKAGE_REQUIRES "qt5-qtbase >= 5.3.2, qt5-qtbase-gui >= 5.3.2")
    set(CPACK_RPM_PACKAGE_SUMMARY "${UN_SUMMARY}")
    set(CPACK_RPM_PACKAGE_DESCRIPTION "${UN_DESCRIPTION}")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.${CPACK_SYSTEM_NAME}")
  endif ()
elseif (WIN32)
  find_program(WINDEPLOYQT windeployqt PATHS ${QT5_ROOT_PATH}/bin/)
  install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION .)
  install(PROGRAMS build/release/tor/bin/tor.exe DESTINATION .)

  if (PACKMSI)
    set(CPACK_GENERATOR NSIS)
  else ()
    set(CPACK_GENERATOR ZIP)
  endif ()
  set(CPACK_PACKAGE_EXECUTABLES "${PROJECT_NAME}" "${PROJECT_NAME}")
  set(CPACK_PACKAGE_INSTALL_DIRECTORY ${PROJECT_NAME})
  set(CPACK_NSIS_MODIFY_PATH ON)
  set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
  set(CPACK_NSIS_MUI_ICON ${CMAKE_SOURCE_DIR}/src/images/UltraNoteLogo.ico)
  set(CPACK_NSIS_MUI_FINISHPAGE_RUN "${PROJECT_NAME}.exe")
  set(CPACK_NSIS_URL_INFO_ABOUT "${UN_CONTACT}")
  set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/COPYING)
  set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
  set(CPACK_NSIS_MENU_LINKS "${UN_CONTACT}" "UltraNote Website")

  add_custom_target(windeployqt ALL
    ${WINDEPLOYQT}
    --dir ${PROJECT_BINARY_DIR}/deploy
    --release
    --compiler-runtime
    --qmldir ${PROJECT_SOURCE_DIR}/src/qml
    $<TARGET_FILE:${PROJECT_NAME}>
    DEPENDS ${PROJECT_NAME}
    COMMENT "Preparing Qt runtime dependencies")
  install(DIRECTORY ${PROJECT_BINARY_DIR}/deploy/ DESTINATION .)

  IF(CMAKE_CL_64)
     SET(CMAKE_MSVC_ARCH x64)
   ELSE(CMAKE_CL_64)
     SET(CMAKE_MSVC_ARCH x86)
  ENDIF(CMAKE_CL_64)

  FIND_PROGRAM(MSVC_REDIST
    NAMES vcredist_${CMAKE_MSVC_ARCH}.exe
    PATHS ${PROJECT_BINARY_DIR}/deploy/)
  GET_FILENAME_COMPONENT(vcredist_name "${MSVC_REDIST}" NAME)
  set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "ExecWait '\\\"$INSTDIR\\\\vcredist_${CMAKE_MSVC_ARCH}.exe\\\" /install /quiet /norestart'")

  #using openSSL 1.1
  set(OPENSSL_PATH "C:/Program Files/OpenSSL-Win64")
  install(FILES ${OPENSSL_PATH}/libcrypto-1_1-x64.dll DESTINATION .)
  install(FILES ${OPENSSL_PATH}/libssl-1_1-x64.dll DESTINATION .)

endif (APPLE)

include(CPack)
