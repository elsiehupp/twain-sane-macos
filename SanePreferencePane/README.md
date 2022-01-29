(Text below lightly adapted from [ellert.se/twain-sane](http://www.ellert.se/twain-sane/).)

# TWAIN SANE Interface for MacOS X

This is a TWAIN datasource for MacOS X that aquires images using the SANE backend libraries. The SANE backend libraries provide access to a large range of scanners connected through SCSI or USB. For a complete list see the documentation on [the SANE project homepage](http://www.sane-project.org/). It works with my HP SCSI scanner, and many people have reported success with a large number of different scanners. The feedback from users have helped the SANE developers to fix problems with various backends, so with each release of the SANE backends more of the MacOS X specific problems have been solved.

The TWAIN SANE interface is not a standalone application. It is designed to be used from within other applications. It works with applications supporting the TWAIN specification, which includes most applications on Mac OS X that handles images. However using it with Apple‘s Image Capture application has become increasingly tricky with every version of Mac OS X. You will have an easier experience if you choose any other application.

The TWAIN SANE Interface is provided as a binary package and as source code. To use the interface you only have to install the binary package. Before installing the TWAIN SANE Interface package you should install the libusb and the sane-backends binary packages.

There is also an optional SANE Preference Pane package available, which makes it easier to configure the sane-backends drivers. If you don’t install this package you can still configure the sane-backends using a text editor in the Terminal.

If you want to compile the sources you also have to install the gettext package. If you are cross-compiling using the MacOS X cross-compilation SDKs you need to install the corresponding SDKs for the used packages.

The **latest version is 3.6**.

## Localizations

The TWAIN SANE Interface has been localized to the following languages: English, French, German, Italian, Japanese, Russian and Swedish. For most of the translation it relies on the localization support in the SANE backend libraries.
