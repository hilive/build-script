#!/bin/bash


NDK=$ANDROID_NDK
BUILD_PLATFORM=darwin
#BUILD_PLATFORM=linux
API_LEVEL=21
AOSP_API=android-$API_LEVEL
BASE_DIR=$(cd `dirname $0`; pwd)


echo "NDK="$NDK
echo "BASE_DIR="$BASE_DIR


rm -f $BASE_DIR/compat/strtod.o

function build_fdkaac
{
cd ../fdk-aac


FLAGS="--enable-static --disable-shared --disable-asm --host=$HOST --target=android "

export CFLAGS="-O3 -DANDROID $ADDI_CFLAGS"
export LDFLAGS="-Wl,-dynamic-linker=/system/bin/linker $ADDI_LDFLAGS"
export CXXFLAGS=$CFLAGS

export CC="${CROSS_COMPILE}gcc --sysroot=${SYSROOT}"
export CXX="${CROSS_COMPILE}g++ --sysroot=${SYSROOT}"
export STRIP="${CROSS_COMPILE}strip"
export RANLIB="${CROSS_COMPILE}ranlib"
export AR="${CROSS_COMPILE}ar"
export LD="${CROSS_COMPILE}ld"
export AS="${CROSS_COMPILE}as"


./configure $FLAGS \
--prefix=$FDK_DIR
$ADDITIONAL_CONFIGURE_FLAG

make clean
make -j16
make install

cd $BASE_DIR
}

function build_x264
{
cd ../libx264

./configure \
--prefix=$X264_DIR \
--enable-static \
--enable-pic \
--enable-shared \
--disable-asm \
--disable-cli \
--cross-prefix=$CROSS_COMPILE \
--host=arm-linux \
--sysroot=$SYSROOT

make -j16
make install

cd $BASE_DIR
}

function build_ffmpeg {
cd ../ffmpeg-hardcode

#./configure -–list-decoders
#./configure -–list-encoders
#./configure -–list-hwaccels 
#./configure -–list-demuxers 
#./configure -–list-muxers 
#./configure -–list-parsers 
#./configure -–list-protocols 
#./configure -–list-bsfs 
#./configure -–list-indevs 
#./configure -–list-outdevs 
#./configure -–list-filters 

./configure \
--prefix=$FFMPEG_DIR \
--enable-cross-compile \
--disable-runtime-cpudetect \
--disable-asm \
--arch=$ARCH \
--target-os=android \
--cc=${CROSS_COMPILE}gcc  \
--cross-prefix=$TOOLCHAIN/bin/$CROSS_PREFIX_BUILD_TOOL_PATH \
--disable-stripping \
--nm=${TOOLCHAIN}/bin/${CROSS_PREFIX_BUILD_TOOL_PATH}nm \
--sysroot=$SYSROOT \
--disable-doc \
--disable-htmlpages \
--disable-podpages \
--disable-txtpages \
--disable-shared \
--disable-postproc \
--disable-indevs \
--disable-outdevs \
--disable-devices \
--disable-ffprobe \
--disable-ffplay \
--disable-ffmpeg \
--disable-debug \
--disable-symver \
--disable-stripping \
--disable-gpl \
--disable-version3 \
--disable-nonfree \
--disable-network \
--enable-libfdk_aac \
--enable-encoder=libfdk_aac \
--enable-jni \
--enable-mediacodec \
--enable-decoder=h264_mediacodec \
--enable-decoder=hevc_mediacodec \
--enable-decoder=mpeg4_mediacodec \
--enable-encoder=h264_mediacodec \
--enable-libx264 \
--enable-encoder=libx264 \
--extra-cflags="-O3 -finline-limit=1000 -fPIC -DANDROID -DHILIVE_SYS_ANDROID -DHILIVE_DEBUG $ADDI_CFLAGS -I$FDK_INC -I$X264_INC" \
--extra-ldflags="$ADDI_LDFLAGS -L$FDK_LIB -L$X264_LIB" \
$ADDITIONAL_CONFIGURE_FLAG

make clean
make -j 16
make install

cd $BASE_DIR
}

function merge_lib
{
OUTPUT_NAME=libmmavmedia.so

mkdir -p $OUTPUT_DIR/include
mkdir -p $OUTPUT_DIR/lib

echo "CROSS_COMPILE="$CROSS_COMPILE
echo "FDK_DIR="$FDK_DIR
echo "X264_DIR="$X264_DIR
echo "FFMPEG_DIR="$FFMPEG_DIR
echo "OUTPUT_DIR="$OUTPUT_DIR
echo "merge lib ..."


cp -r $FFMPEG_INC/* $OUTPUT_DIR/include

${CROSS_COMPILE}ld -rpath-link=$SYSROOT/usr/lib -L$SYSROOT/usr/lib -L$PREFIX/lib -soname $OUTPUT_NAME -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o $OUTPUT_DIR/lib/$OUTPUT_NAME \
    $FDK_LIB/libfdk-aac.a \
    $X264_LIB/libx264.a \
    $FFMPEG_LIB/libavcodec.a \
    $FFMPEG_LIB/libswresample.a \
    $FFMPEG_LIB/libswscale.a \
    $FFMPEG_LIB/libavformat.a \
    $FFMPEG_LIB/libavfilter.a \
    $FFMPEG_LIB/libavutil.a \
    -lc -lm -lz -ldl -llog -lmediandk --dynamic-linker=/system/bin/linker $TOOLCHAIN/lib/gcc/$HOST/4.9.x/libgcc.a

}

function build_one
{
CROSS_COMPILE=${TOOLCHAIN}/bin/${CROSS_PREFIX_BUILD_TOOL_PATH}

FDK_DIR=$BASE_DIR/binary/android/fdkaac/$CPU
FDK_INC=$FDK_DIR/include
FDK_LIB=$FDK_DIR/lib

X264_DIR=$BASE_DIR/binary/android/x264/$CPU
X264_INC=$X264_DIR/include
X264_LIB=$X264_DIR/lib

FFMPEG_DIR=$BASE_DIR/binary/android/ffmpeg/$CPU
FFMPEG_INC=$FFMPEG_DIR/include
FFMPEG_LIB=$FFMPEG_DIR/lib

OUTPUT_DIR=$BASE_DIR/output/android/$CPU

#build_fdkaac
#build_x264
build_ffmpeg
merge_lib
}

#add for wexin dec_build_android.sh
SYSROOT=$NDK/platforms/$AOSP_API/arch-arm
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/$BUILD_PLATFORM-x86_64
HOST=arm-linux-androideabi
CROSS_PREFIX_BUILD_TOOL_PATH=$HOST-
ARCH=arm
CPU=arm
ADDI_CFLAGS="-marm"
#build_one

#arm
SYSROOT=$NDK/platforms/$AOSP_API/arch-arm
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/$BUILD_PLATFORM-x86_64
HOST=arm-linux-androideabi
CROSS_PREFIX_BUILD_TOOL_PATH=$HOST-
ARCH=arm
CPU=armv5te
ADDI_CFLAGS="-marm -fPIC"
ADDITIONAL_CONFIGURE_FLAG="--disable-neon --enable-armv5te --disable-armv6 --disable-armv6t2 --disable-vfp"
#build_one

#armv7-neon
SYSROOT=$NDK/platforms/$AOSP_API/arch-arm
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/$BUILD_PLATFORM-x86_64
HOST=arm-linux-androideabi
CROSS_PREFIX_BUILD_TOOL_PATH=$HOST-
ARCH=arm
CPU=armv7-neon
ADDI_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -march=armv7-a"
ADDI_LDFLAGS="-Wl,--fix-cortex-a8"
ADDITIONAL_CONFIGURE_FLAG="--enable-neon --enable-armv5te --enable-armv6 --enable-armv6t2 --enable-vfp"
build_one

#arm64-v8a
SYSROOT=$NDK/platforms/$AOSP_API/arch-arm64
TOOLCHAIN=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/$BUILD_PLATFORM-x86_64
HOST=aarch64-linux-android
CROSS_PREFIX_BUILD_TOOL_PATH=$HOST-
ARCH=arm64
CPU=arm64-v8a
ADDI_CFLAGS="-march=armv8-a" 
ADDI_LDFLAGS=""
ADDITIONAL_CONFIGURE_FLAG="--enable-vfp"
build_one

#x86
FFMPEG_ASM_FLAGS="--disable-asm"
SYSROOT=$NDK/platforms/$AOSP_API/arch-x86
TOOLCHAIN=$NDK/toolchains/x86-4.9/prebuilt/$BUILD_PLATFORM-x86_64
HOST=i686-linux-android
CROSS_PREFIX_BUILD_TOOL_PATH=$HOST-
ARCH=x86
CPU=x86
ADDI_CFLAGS="-march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32"
ADDI_LDFLAGS="-Wl,--fix-cortex-a8"
ADDITIONAL_CONFIGURE_FLAG="--enable-vfp"
#build_one


#x86_64
SYSROOT=$NDK/platforms/$AOSP_API/arch-x86_64
TOOLCHAIN=$NDK/toolchains/x86_64-4.9/prebuilt/$BUILD_PLATFORM-x86_64
HOST=x86_64-linux-android
CROSS_PREFIX_BUILD_TOOL_PATH=$HOST-
ARCH=x86_64
CPU=x86_64
ADDI_CFLAGS="-march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
ADDI_LDFLAGS="-Wl,--fix-cortex-a8"
ADDITIONAL_CONFIGURE_FLAG="--enable-vfp"
#build_one

