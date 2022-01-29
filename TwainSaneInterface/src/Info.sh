#! /bin/sh

cat Info.plist.in |
(
    IFS=
    while read line ; do
	echo $line | grep -q "device info version"
	if [ $? -eq 0 ] ; then
	    cat <<EOF
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>SANE</string>
	<key>CFBundleIconFile</key>
	<string>SANE.icns</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>3.6</string>
	<key>CFBundleSignature</key>
	<string>SANE</string>
	<key>CFBundleVersion</key>
	<string>3.6</string>
	<key>CSResourcesFileMapped</key>
	<true/>
	<key>SANELocaleDir</key>
	<string>/usr/local/share/locale</string>
EOF
	fi
	echo $line
    done
)
