#!/bin/bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
        echo "Build for linux-gnu"
        rp=$(realpath .)
        cd ./tor
        ./autogen.sh
        ./configure --with-libevent-dir=/usr --disable-asciidoc --prefix=$rp/build/release/tor
        make
        make install
        #make clean
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Build for macOS"
        rp=$(pwd) # macOS have not realpath utility
        cd ./tor
        ./autogen.sh
        ./configure --enable-static-libevent --with-libevent-dir=/usr/local --enable-static-openssl --with-openssl-dir=/usr/local --disable-asciidoc --prefix=$rp/build/release/tor
        make
        make install
        #make clean
        #echo "NOT IMPLEMENTED YET"
        #exit
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        echo "Build for windows under sygwin/msys"
        rp=$(realpath .)
        cd ./tor
        ./autogen.sh
        ./configure --enable-static-tor --with-libevent-dir=/mingw64 --with-openssl-dir=/mingw64 --with-zlib-dir=/mingw64 --disable-asciidoc --prefix=$rp/build/release/tor
        echo "#define HAVE_SSL_GET_CLIENT_CIPHERS 1" >> orconfig.h
        echo "#define HAVE_SSL_GET_CLIENT_RANDOM 1" >> orconfig.h
        echo "#define HAVE_SSL_GET_SERVER_RANDOM 1" >> orconfig.h
        echo "#define HAVE_SSL_SESSION_GET_MASTER_KEY 1" >> orconfig.h
        make
        make install
        cp $rp/build/release/tor/bin/tor.exe $rp/build/release/Release/
        #make clean
elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
        echo "IMPOSSIBRU!"
        exit
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "THIS PLATFORM NOT SUPPORTED"
else
        echo "UNKNOWN PLATFORM"
        exit
fi

echo ""
echo "ALL IS DONE."
