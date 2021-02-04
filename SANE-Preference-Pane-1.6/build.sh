#!/bin/sh

DSTNAME=SANE-Preference-Pane
DSTVERSION=1.6

MACOSX_DEPLOYMENT_TARGET=10.6

NEXT_ROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

if [ ! -d "$NEXT_ROOT" ]; then
    echo "Error: SDK not found."
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

    xcodebuild -project SANEPref.xcodeproj -configuration Release \
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
    --identifier se.ellert.preference.sane --version $DSTVERSION \
    /tmp/SANE-Preference-Pane.pkg

productbuild --distribution $RESOURCEDIR/distribution.xml \
    --identifier se.ellert.preference.sane --version $DSTVERSION \
    --resources $RESOURCEDIR --package-path /tmp $PKG

rm /tmp/SANE-Preference-Pane.pkg
rm -rf $RESOURCEDIR

sudo rm -rf $DSTROOT
