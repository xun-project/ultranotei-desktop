.DEFAULT_GOAL := build-release

# detect WindowsXT
ifeq ($(OS),Windows_NT)
	IS_WIN:=1
endif

# detect Windows
ifdef SYSTEMROOT
	IS_WIN:=1
endif

ifdef IS_WIN
   RM = del /Q
else
   ifeq ($(shell uname), Linux)
      RM = rm -rf
   endif
   ifeq ($(shell uname), Darwin)
      RM = rm -rf
   endif
endif

ifdef IS_WIN
	WINDOWS_BUILD_OPT := "-G \"Visual Studio 15 2017\""
	ifeq ($(WINDOWS_BUILD),Win64)
		WINDOWS_BUILD_OPT := "-G \"Visual Studio 15 2017 Win64\""
	else
		ifeq ($(WINDOWS_BUILD),Win32)
			WINDOWS_BUILD_OPT := "-G \"Visual Studio 15 2017\""
		else
			ifdef WINDOWS_BUILD
				WINDOWS_BUILD_OPT := "-G $(WINDOWS_BUILD)"
			endif
		endif
	endif
endif

ifdef QT5_ROOT_PATH
	QT5_OPT := -DQT5_ROOT_PATH=$(QT5_ROOT_PATH)
endif

all: all-release

make-debug-dir:
	mkdir -p build/debug

make-release-dir:
	mkdir -p build/release

cmake-debug: make-debug-dir
	cd build/debug && cmake -DCMAKE_BUILD_TYPE=Debug $(QT5_OPT) ../..

build-debug: cmake-debug
	$(MAKE) -C build/debug -j4

test-debug: build-debug
	$(MAKE) -C build/debug test

all-debug: build-debug

cmake-release: make-release-dir
	cd build/release && cmake -DCMAKE_BUILD_TYPE=Release $(QT5_OPT) ../..

build-release: cmake-release
	$(MAKE) -C build/release -j4

test-release: build-release
	$(MAKE) -C build/release test

all-release: build-release

package-deb: make-release-dir
	cd build/release && cmake -DCMAKE_BUILD_TYPE=Release -DPACKRPM=0 $(QT5_OPT) ../..
	$(MAKE) -C build/release -j4 package

package-rpm: make-release-dir
	cd build/release && cmake -DCMAKE_BUILD_TYPE=Release -DPACKRPM=1 $(QT5_OPT)  ../..
	$(MAKE) -C build/release -j4 package

package-dmg: make-release-dir
	cd build/release && cmake -DCMAKE_BUILD_TYPE=Release $(QT5_OPT) ../..
	$(MAKE) -C build/release -j4 package

package-msi: make-release-dir
	cd build/release && cmake -DCMAKE_BUILD_TYPE=Release $(QT5_OPT) $(WINDOWS_BUILD_OPT) -DPACKMSI=1 ../..
	cd build/release && cmake --build . --config Release
	cd build/release && cpack -C Release

package-zip: make-release-dir
	cd build/release && cmake -DCMAKE_BUILD_TYPE=Release $(QT5_OPT) $(WINDOWS_BUILD_OPT) -DPACKZIP=1 ../..
	cd build/release && cmake --build . --config Release
	cd build/release && cpack -C Release

clean:
	$(RM) build/release build/debug

tags:
	ctags -R --sort=1 --c++-kinds=+p --fields=+iaS --extra=+q --language-force=C++ src contrib tests/gtest

.PHONY: all cmake-debug build-debug test-debug all-debug cmake-release build-release test-release all-release clean tags
