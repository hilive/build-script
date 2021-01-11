#!/bin/bash

BASE_DIR=$(cd `dirname $0`; pwd)

SOURCE_DIR=$BASE_DIR/protobuf
OUTPUT_DIR=$SOURCE_DIR/android/

if [ ! -r $SOURCE_DIR ]
then
  git clone https://github.com/protocolbuffers/protobuf.git protobuf
fi


export NDK_ROOT=/Users/cortxu/Tools/android-ndk-r21b
export PREFIX=$OUTPUT_DIR/tmp
export PATH=$NDK_ROOT/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/arm-linux-androideabi/bin:$PATH
export SYSROOT=$NDK_ROOT/sysroot
export CC="arm-linux-androideabi-gcc --sysroot $SYSROOT"
export CXX="arm-linux-androideabi-g++ --sysroot $SYSROOT"
export CXXSTL=$NDK_ROOT/sources/cxx-stl/llvm-libc++

./protobuf/autogen.sh

./protobuf/configure \
--prefix=$PREFIX \
--host=arm-linux-androideabi \
--with-sysroot="${SYSROOT}" \
--enable-shared \
--enable-cross-compile \
--with-protoc=protoc \
CFLAGS="-march=armv7-a -D__ANDROID_API__=21" \
CXXFLAGS="-frtti -fexceptions -march=armv7-a \
-I${NDK_ROOT}/sources/cxx-stl/llvm-libc++/include \
-I${NDK_ROOT}/sources/cxx-stl/llvm-libc++/include \
-I${NDK_ROOT}/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a -D__ANDROID_API__=21" \
LDFLAGS="-L${NDK_ROOT}/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a " \
LIBS="-llog -lz -lc++_static"

make -j2

make install