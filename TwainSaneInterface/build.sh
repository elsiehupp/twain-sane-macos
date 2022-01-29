#!/bin/sh

DSTNAME=TWAIN-SANE-Interface
DSTVERSION=3.6

MACOSX_DEPLOYMENT_TARGET=10.9

NEXT_ROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

if [ ! -d "$NEXT_ROOT" ]; then
    echo "Error: SDK not found."
    exit 1
fi

if [ ! -f /usr/local/lib/libintl.a ]; then
    echo "Error: You should install the gettext package before building $DSTNAME."
    exit 1
fi

if [ ! -f /usr/local/lib/libusb.dylib ]; then
    echo "Error: You should install the libusb package before building $DSTNAME."
    exit 1
fi

if [ ! -f /usr/local/lib/libsane.dylib ]; then
    echo "Error: You should install the sane-backends package before building $DSTNAME."
    exit 1
fi

SRCDIR=`pwd`/src
BUILD=/tmp/$DSTNAME.build
DSTROOT=/tmp/$DSTNAME.dst

[ -e $BUILD ]   && (      rm -rf $BUILD   || exit 1 )
[ -e $DSTROOT ] && ( sudo rm -rf $DSTROOT || exit 1 )

cp -pr $SRCDIR $BUILD

(
    cd $BUILD

    ./Info.sh > Info.plist

    xcodebuild -project SANE.ds.xcodeproj -configuration Release \
	install DSTROOT=$DSTROOT
)

rm -rf $BUILD

sudo chown -Rh root:admin $DSTROOT
sudo chmod -R 775 $DSTROOT
sudo chmod 1775 $DSTROOT

PKG=`pwd`/../PKGS/$DSTNAME.pkg
[ -e $PKG ]        && ( rm -rf $PKG        || exit 1 )
[ -e $PKG.tar.gz ] && ( rm -rf $PKG.tar.gz || exit 1 )
mkdir -p ../PKGS

RESOURCEDIR=/tmp/$DSTNAME.resources
[ -e $RESOURCEDIR ] && ( rm -rf $RESOURCEDIR || exit 1 )
mkdir -p $RESOURCEDIR

(
    cd pkg/Resources
    for d in `find . -type d` ; do
	mkdir -p $RESOURCEDIR/$d
    done
    for f in `find . -type f -a ! -name .DS_Store -a ! -name '*.gif'` ; do
	sed -e s/@MACOSX_DEPLOYMENT_TARGET@/$MACOSX_DEPLOYMENT_TARGET/g \
	    -e s/@DSTVERSION@/$DSTVERSION/g \
	    < $f > $RESOURCEDIR/$f
    done
    cp -p *.gif $RESOURCEDIR
)

pkgbuild --root $DSTROOT --ownership recommended \
    --identifier se.ellert.twain-sane --version $DSTVERSION \
    /tmp/TWAIN-SANE-Interface.pkg

productbuild --distribution $RESOURCEDIR/distribution.xml \
    --identifier se.ellert.twain-sane --version $DSTVERSION \
    --resources $RESOURCEDIR --package-path /tmp $PKG

rm /tmp/TWAIN-SANE-Interface.pkg
rm -rf $RESOURCEDIR

sudo rm -rf $DSTROOT
