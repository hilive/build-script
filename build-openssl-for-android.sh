#!/bin/bash

BASE_DIR=$(cd `dirname $0`; pwd)

OPENSSL_PATH=../openssl-1.1.1d
#输出路径
PREFIX=$BASE_DIR/binary/android/openssl
COMP_BUILD=$1
ANDROID_API=21
NDK=$ANDROID_NDK

if [ ! "$COMP_BUILD" ]
then
COMP_BUILD="all"
fi

echo COMP_BUILD=$COMP_BUILD
echo ANDROID_API=$ANDROID_API
echo NDK=$NDK

#需要编译的平台:arm arm64 x86 x86_64
ARCHS=(arm arm64 x86 x86_64)
TRIPLES=(arm-linux-androideabi aarch64-linux-android i686-linux-android x86_64-linux-android)
TRIPLES_PATH=(arm-linux-androideabi-4.9 aarch64-linux-android-4.9 x86-4.9 x86_64-4.9)

#FF_CONFIGURE_FLAGS="-D__ANDROID_API__=$ANDROID_API no-ssl2 no-ssl3 no-comp no-hw no-engine"
#FF_CONFIGURE_FLAGS="-D__ANDROID_API__=$ANDROID_API no-engine"
FF_CONFIGURE_FLAGS="-D__ANDROID_API__=$ANDROID_API no-engine no-shared no-asm no-ssl2 no-ssl3 no-dso no-sse2 no-threads no-zlib"

#rm -rf "$PREFIX"
#rm -rf "$SOURCE"
if [ ! -r $SOURCE ]
then
    OPENSSL_TAR_NAME="$SOURCE.tar.gz"
    if [ ! -f "$SHELL_PATH/$OPENSSL_TAR_NAME" ]
    then
        echo "$SHELL_PATH/$OPENSSL_TAR_NAME source not found, Trying to download..."
        curl -O https://www.openssl.org/source/$OPENSSL_TAR_NAME
    fi
    mkdir $OPENSSL_PATH
    tar zxvf $SHELL_PATH/$OPENSSL_TAR_NAME --strip-components 1 -C $OPENSSL_PATH || exit 1
fi

cd $OPENSSL_PATH
for i in "${!ARCHS[@]}";
do
    ARCH=${ARCHS[$i]}
    PREFIX_ARCH=$PREFIX/$ARCH

    export ANDROID_NDK=$NDK
    export PATH=$NDK/toolchains/${TRIPLES_PATH[$i]}/prebuilt/darwin-x86_64//bin:$PATH
    CC=gcc
    echo PATH=$PATH
    if [ "$COMP_BUILD" = "all" -o "$COMP_BUILD" = "$ARCH" ]
    then
        TRMP_P=""
        if [ "$ARCH" = "arm" ]
        then
            TRMP_P="v7-neon"
            export ARCH=$ARCH$TRMP_P
            PREFIX_ARCH="$PREFIX_ARCH$TRMP_P"
            FF_FLAGS="$FF_CONFIGURE_FLAGS android-arm"
        elif [ "$ARCH" = "arm64" ]
        then
            TRMP_P="-v8a"
            PREFIX_ARCH="$PREFIX_ARCH$TRMP_P"
            export ARCH=$ARCH$TRMP_P
            FF_FLAGS="$FF_CONFIGURE_FLAGS android-arm64"
        elif [ "$ARCH" = "x86_64" ]
        then
            export ARCH=$ARCH
            FF_FLAGS="$FF_CONFIGURE_FLAGS android-x86_64"
        elif [ "$ARCH" = "x86" ]
        then
            export ARCH=$ARCH
            FF_FLAGS="$FF_CONFIGURE_FLAGS android-x86"
        fi
    else
        continue
    fi

    echo FF_FLAGS=$FF_FLAGS

    ./Configure \
    --prefix=$PREFIX_ARCH \
    $FF_FLAGS || exit 1
    make -j16 && make -j16 install || exit 1
    make clean
    rm -rf "$PREFIX_ARCH/share" "$PREFIX_ARCH/bin" "$PREFIX_ARCH/ssl"
#    if [[ $FF_FLAGS == *no-shared* ]]
#    then
#        mv $PREFIX_ARCH/lib/libcrypto.so.* $PREFIX_ARCH/lib/libcrypto.so
#        mv $PREFIX_ARCH/lib/libssl.so.* $PREFIX_ARCH/lib/libssl.so
#    fi
done

echo "Android openssl bulid success!"


