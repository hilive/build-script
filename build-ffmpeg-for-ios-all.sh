#!/bin/sh

# directories
BASE_DIR=$(cd `dirname $0`; pwd)
DEPLOYMENT_TARGET="8.0"
BINARY_DIR=$BASE_DIR/binary/ios/ffmpeg/
OUTPUT_DIR=$BASE_DIR/output/ios/

function install_tool
{
if [ ! `which yasm` ]
then
	echo 'Yasm not found'
	if [ ! `which brew` ]
	then
		echo 'Homebrew not found. Trying to install...'
											ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
			|| exit 1
	fi
	echo 'Trying to install Yasm...'
	brew install yasm || exit 1
fi
if [ ! `which gas-preprocessor.pl` ]
then
	echo 'gas-preprocessor.pl not found. Trying to install...'
	(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
		-o /usr/local/bin/gas-preprocessor.pl \
		&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
		|| exit 1
fi
}

function build_ffmpeg
{
install_tool

CONFIGURE_FLAGS="--enable-cross-compile \
--disable-debug \
--disable-programs \
--disable-doc \
--disable-htmlpages \
--disable-manpages \
--disable-podpages \
--disable-txtpages \
--disable-shared \
--disable-ffmpeg \
--disable-ffplay \
--disable-ffprobe \
--disable-symver \
--disable-stripping \
--disable-gpl \
--disable-version3 \
--disable-nonfree \
--disable-avdevice \
--enable-small \
--enable-static \
--enable-asm \
--enable-neon \
--enable-filters \
--extra-cflags=-g \
--extra-cflags=-gline-tables-only \
"

ARCHS="arm64 x86_64"

cd $BASE_DIR/../ffmpeg-hardcode

for ARCH in $ARCHS
do
	echo "building $ARCH..."

	CFLAGS="-arch $ARCH"
	if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
	then
			PLATFORM="iPhoneSimulator"
			CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
	else
			PLATFORM="iPhoneOS"
			CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
			if [ "$ARCH" = "arm64" ]
			then
					EXPORT="GASPP_FIX_XCODE5=1"
			fi
	fi

	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
	CC="xcrun -sdk $XCRUN_SDK clang"

	# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
	if [ "$ARCH" = "arm64" ]
	then
			AS="gas-preprocessor.pl -arch aarch64 -- $CC"
	else
			AS="gas-preprocessor.pl -- $CC"
	fi

	CXXFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"

	echo "building fat binaries..."
#	TMPDIR=${TMPDIR/%\/} ./configure \
	./configure \
			--target-os=darwin \
			--arch=$ARCH \
			--cc="$CC" \
			--as="$AS" \
			$CONFIGURE_FLAGS \
			--extra-cflags="$CFLAGS" \
			--extra-ldflags="$LDFLAGS" \
			--prefix="$BINARY_DIR/$ARCH" \
	|| exit 1

	make -j8 install $EXPORT || exit 1
done

cd $BASE_DIR
}

function merge_lib
{
echo "merge lib"
mkdir -p $OUTPUT_DIR/lib
set - $ARCHS
cd $BINARY_DIR/$1/lib
for LIB in *.a
do
	cd $BASE_DIR
	echo lipo -create `find $BINARY_DIR -name $LIB` -output $OUTPUT_DIR/lib/$LIB 1>&2
	lipo -create `find $BINARY_DIR -name $LIB` -output $OUTPUT_DIR/lib/$LIB || exit 1
done

cd $CWD
cp -rf $BINARY_DIR/$1/include $OUTPUT_DIR
}

build_ffmpeg
merge_lib

echo "build complete"
