#!/bin/sh

# svn export http://libusb.svn.sourceforge.net/svnroot/libusb/trunk/libusb

DSTNAME=libusb
DSTVERSION=0.1.13

PATH=`sed -e 's!/opt/local/bin!!' \
	  -e 's!/opt/local/sbin!!' \
	  -e 's!^:*!!' -e 's!:*$!!' -e 's!::*!:!g' <<< $PATH`
export PATH=$PATH:/opt/local/bin:/opt/local/sbin

MACOSX_DEPLOYMENT_TARGET=10.7
ARCHS="i386 x86_64"

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

for d in $DSTROOT-* ; do ( rm -rf $d || exit 1 ) ; done

mkdir $BUILD

(
    cd $BUILD
    tar -z -x -f $SRCDIR/$DSTNAME-2016-11-02-svn.tar.gz

    cd $DSTNAME-2016-11-02-svn

    patch -p1 < $SRCDIR/libusb-cxx.patch
    patch -p1 < $SRCDIR/libusb-64bit.patch
    patch -p1 < $SRCDIR/libusb-endian.patch
    patch -p1 < $SRCDIR/libusb-runloop.patch

    aclocal
    glibtoolize --force
    autoheader
    automake --add-missing --force
    autoconf

    CC="/usr/bin/clang -isysroot $NEXT_ROOT"
    CXX="/usr/bin/clang++ -isysroot $NEXT_ROOT"
    CPP="/usr/bin/clang -E -isysroot $NEXT_ROOT"

    LDFLAGS=""

    export PATH=$NEXT_ROOT/usr/bin:$PATH
    export MACOSX_DEPLOYMENT_TARGET
    export NEXT_ROOT

    export LD_PREBIND_ALLOW_OVERLAP=1

    if [ -n "$ARCHS" ]; then
	for arch in $ARCHS ; do
	    CC=$CC CFLAGS="$CFLAGS -arch $arch" \
		CXX=$CXX CXXFLAGS="$CXXFLAGS -arch $arch" \
		CPP=$CPP CPPFLAGS="$CPPFLAGS -arch $arch" \
		LDFLAGS="$LDFLAGS -arch $arch" \
		./configure --build `./config.guess`
	    make
	    make install DESTDIR=$DSTROOT-$arch
	    make clean
	done
	mkdir $DSTROOT
	arch=`./config.guess | \
	    sed -e s/-.*// -e s/i.86/i386/ -e s/powerpc/ppc/`
	[ "$arch" = "ppc" -a ! -d $DSTROOT-ppc ] && arch=ppc7400
	[ ! -d $DSTROOT-$arch ] && arch=`sed "s/ .*//" <<< $ARCHS`
	for d in `(cd $DSTROOT-$arch ; find . -type d)` ; do
	    mkdir -p $DSTROOT/$d
	done
	for f in `(cd $DSTROOT-$arch ; find . -type f)` ; do
	    if [ `wc -w <<< $ARCHS` -gt 1 ] ; then
		file $DSTROOT-$arch/$f | grep -q -e 'Mach-O\|ar archive'
		if [ $? -eq 0 ] ; then
		    lipo -c -o $DSTROOT/$f $DSTROOT-*/$f
		else
		    cp -p $DSTROOT-$arch/$f $DSTROOT/$f
		fi
	    else
		cp -p $DSTROOT-$arch/$f $DSTROOT/$f
	    fi
	done
	for l in `(cd $DSTROOT-$arch ; find . -type l)` ; do
	    cp -pR $DSTROOT-$arch/$l $DSTROOT/$l
	done
	rm -rf $DSTROOT-*
    else
	CC=$CC CFLAGS="$CFLAGS" \
	    CXX=$CXX CXXFLAGS="$CXXFLAGS" \
	    CPP=$CPP CPPFLAGS="$CPPFLAGS" \
	    LDFLAGS="$LDFLAGS" \
	    ./configure
	make
	make install DESTDIR=$DSTROOT
    fi
)

rm -rf $BUILD

sudo chown -Rh root:wheel $DSTROOT
sudo chown root:admin $DSTROOT
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
    for f in `find . -type f -a ! -name .DS_Store` ; do
	sed -e s/@MACOSX_DEPLOYMENT_TARGET@/$MACOSX_DEPLOYMENT_TARGET/g \
	    -e s/@DSTVERSION@/$DSTVERSION/g \
	    < $f > $RESOURCEDIR/$f
    done
)

pkgbuild --root $DSTROOT --ownership recommended \
    --identifier net.sourceforge.libusb --version $DSTVERSION /tmp/libusb.pkg

productbuild --distribution $RESOURCEDIR/distribution.xml \
    --identifier net.sourceforge.libusb --version $DSTVERSION \
    --resources $RESOURCEDIR --package-path /tmp $PKG

rm /tmp/libusb.pkg
rm -rf $RESOURCEDIR

sudo rm -rf $DSTROOT
