> ## Note
> 
> This repository aggregates the source code components available at [ellert.se/twain-sane](http://www.ellert.se/twain-sane/) for the purpose of setting up a Git workspace for the project of getting the TWAIN SANE Interface running in 64-bit for current versions of macOS.
> 
> ***The contents of this repository do not currently compile.***
> 
> I do not anticipate making progress on this project myself in the foreseeable future, as, among other things, I have very little experience with Cocoa and Objective-C, and learning macOS development is not a current focus for me.
> 
> Please feel free to fork this repository as a base for working on it yourself, and please do tag me if you make any progress!
> 
> — Elsie Hupp ([@elsiehupp](https://github.com/elsiehupp)) September 2021

---

(Text below lightly adapted from [ellert.se/twain-sane](http://www.ellert.se/twain-sane/).)

# TWAIN SANE Interface for MacOS X

This is a TWAIN datasource for MacOS X that aquires images using the SANE backend libraries. The SANE backend libraries provide access to a large range of scanners connected through SCSI or USB. For a complete list see the documentation on [the SANE project homepage](http://www.sane-project.org/). It works with my HP SCSI scanner, and many people have reported success with a large number of different scanners. The feedback from users have helped the SANE developers to fix problems with various backends, so with each release of the SANE backends more of the MacOS X specific problems have been solved.

The TWAIN SANE interface is not a standalone application. It is designed to be used from within other applications. It works with applications supporting the TWAIN specification, which includes most applications on Mac OS X that handles images. However using it with Apple‘s Image Capture application has become increasingly tricky with every version of Mac OS X. You will have an easier experience if you choose any other application.

The TWAIN SANE Interface is provided as a binary package and as source code. To use the interface you only have to install the binary package. Before installing the TWAIN SANE Interface package you should install the libusb and the sane-backends binary packages.

There is also a optional SANE Preference Pane package available, which makes it easier to configure the sane-backends drivers. If you don’t install this package you can still configure the sane-backends using a text editor in the Terminal.

If you want to compile the sources you also have to install the gettext package. If you are cross-compiling using the MacOS X cross-compilation SDKs you need to install the corresponding SDKs for the used packages.

The **latest version is 3.6**.

## Localizations

The TWAIN SANE Interface has been localized to the following languages: English, French, German, Italian, Japanese, Russian and Swedish. For most of the translation it relies on the localization support in the SANE backend libraries.
