#!/bin/bash

QT_VER=5.13.0

rm -rf build

mkdir build
cd build

cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$HOME/Qt/$QT_VER/clang_64
make -j

make package
