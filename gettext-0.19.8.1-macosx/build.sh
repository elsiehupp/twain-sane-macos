#!/bin/sh

DSTNAME=gettext
DSTVERSION=0.19.8.1

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
    tar -J -x -f $SRCDIR/$DSTNAME-$DSTVERSION.tar.xz

    cd $DSTNAME-$DSTVERSION

    CC="/usr/bin/clang -isysroot $NEXT_ROOT"
    CXX="/usr/bin/clang++ -isysroot $NEXT_ROOT"
    CPP="/usr/bin/clang -E -isysroot $NEXT_ROOT"

    CFLAGS="-I$NEXT_ROOT/usr/include/libxml2"
    CXXFLAGS="-I$NEXT_ROOT/usr/include/libxml2"
    CPPFLAGS="-I$NEXT_ROOT/usr/include/libxml2"
    LDFLAGS=""

    export PATH=$NEXT_ROOT/usr/bin:$PATH
    export MACOSX_DEPLOYMENT_TARGET
    export NEXT_ROOT

    if [ -n "$ARCHS" ]; then
	for arch in $ARCHS ; do
	    CC=$CC CFLAGS="$CFLAGS -arch $arch" \
		CXX=$CXX CXXFLAGS="$CXXFLAGS -arch $arch" \
		CPP=$CPP CPPFLAGS="$CPPFLAGS -arch $arch" \
		LDFLAGS="$LDFLAGS -arch $arch" \
		./configure --with-included-gettext \
		--disable-java --disable-native-java \
		--disable-shared --build `./build-aux/config.guess`
	    make
	    make install DESTDIR=$DSTROOT-$arch
	    make clean
	done
	mkdir $DSTROOT
	arch=`./build-aux/config.guess | \
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
	    ./configure --with-included-gettext \
	    --disable-java --disable-native-java \
	    --disable-shared
	make
	make install DESTDIR=$DSTROOT
    fi

    for f in `find $DSTROOT -name *.la` ; do
	sed "s#\([^ ]*\)/lib\([^ ]*\).la#-L\1 -l\2#g" < $f > $f.tmp
	mv -f $f.tmp $f
	if [ -n "$NEXT_ROOT" ] ; then
	    grep -q "$NEXT_ROOT" $f
	    if [ $? -eq 0 ] ; then
		sed "s#-[LR]$NEXT_ROOT[^ ]* ##g" < $f > $f.tmp
		mv -f $f.tmp $f
	    fi
	fi
    done
)

rm -f $DSTROOT/usr/local/lib/charset.alias
rm -f $DSTROOT/usr/local/lib/libgettextlib.la
rm -f $DSTROOT/usr/local/lib/libgettextsrc.la

rm -f $DSTROOT/usr/local/include/gettext-po.h
rm -f $DSTROOT/usr/local/lib/libgettextpo.a
rm -f $DSTROOT/usr/local/lib/libgettextpo.la

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
    --identifier org.gnu.gettext --version $DSTVERSION /tmp/gettext.pkg

productbuild --distribution $RESOURCEDIR/distribution.xml \
    --identifier org.gnu.gettext --version $DSTVERSION \
    --resources $RESOURCEDIR --package-path /tmp $PKG

rm /tmp/gettext.pkg
rm -rf $RESOURCEDIR

sudo rm -rf $DSTROOT
