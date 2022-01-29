# TWAIN-SANE Interface for macOS

## Introduction

This repository aggregates the source code components available at [ellert.se/twain-sane](http://www.ellert.se/twain-sane/) for the purpose of setting up a Git workspace for the project of getting the TWAIN SANE Interface running in 64-bit for current versions of macOS.

***The contents of this repository do not currently compile.***

I do not anticipate making progress on this project myself in the foreseeable future, as, among other things, I have very little experience with Cocoa and Objective-C, and learning macOS development is not a current focus for me.

Please feel free to fork this repository as a base for working on it yourself, and please do tag me if you make any progress!

— Elsie Hupp ([@elsiehupp](https://github.com/elsiehupp)) September 2021

## Repository Contents

This repository includes three subdirectories:

### `TwainSaneInterface`

This package is the core of Mattias Ellert's project. It maps SANE's API to a TWAIN API and provides a graphical user interface for use within Apple Image Capture and macOS applications that use Image Capture as a scanner or camera interface. (This package does not compile and has not been adapted to Homebrew-installed `sane-backends`.)

> The contents of `TwainSaneInterface` are licensed under the GPLv2.

### `SanePreferencePane`

This optional [Preference Pane](https://developer.apple.com/documentation/preferencepanes) package from Mattias Ellert's project makes it easier to configure the `sane-backends` drivers. If you don’t install this package you can still configure the `sane-backends` using a text editor in the Terminal. (This package does not compile and has not been adapted to Homebrew-installed `sane-backends`. Oddly, the compiled version of this did run correctly under macOS 11, even though the compiled `TwainSaneInterface` did not. I think this may just be due to how Preference Panes work.)

> The contents of `SanePreferencePane` are licensed under the GPLv2.

### `VirtualScanner`

This is a sample project [from Apple's Developer documentation archive](https://developer.apple.com/library/archive/samplecode/VirtualScanner/Introduction/Intro.html). I have included it because does not seem to depend on `Carbon.framework`, though it still does not compile (albeit for different reasons.).

> The contents of `VirtualScanner` are licensed under Apple's version of the MIT License.

## External Requirements

After doing some further digging, I have simplified the contents of this repository to exclude the dependencies available through [Homebrew](https://brew.sh/). Rather than including an ancient version of the source code for `sane-backends`, I would encourage you to install the fully maintained Homebrew version using the following Terminal commands:

### 1. Install Homebrew (if you haven't already):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install `sane-backends`:

```bash
brew install sane-backends
```

The advantage with this approach is that the version you have installed will be completely up-to-date. I have not updated any of the code to dynamically linking to the Homebrew version, though, because I'm not sure exactly what would be involved.

## Problem Statement

Mattias Ellert's original code no longer compiles on current versions of macOS due to two prerequisite Apple libraries never making the jump to 64-bit:

1. [`Carbon.framework`](https://en.wikipedia.org/wiki/Carbon_(API)) (Yes, we knew this fourteen years ago.)
2. `ICADevices.framework` (Depends on `Carbon.framework`)

Additionally, `TWAIN.framework` doesn't appear in Apple's current Developer documentation, but I checked on my Mac (running macOS 12.1), and `/System/Library/Frameworks/TWAIN.framework` is still there, so seemingly it's still current.

Regardless, Apple no longer provides any current references for creating scanner drivers in particular. As best I can tell, approaches that might work for modernizing the TWAIN-SANE Interface are as follows:

* At the very least, port the existing `TwainSaneInterface` (and maybe `SanePreferencePane`) code to access `sane-backends` dynamically, and port it from `Carbon.framework` to `Cocoa.framework` (or even SwiftUI).
* Maybe create a wrapper for `sane-backends` using [`DriverKit`](https://developer.apple.com/documentation/driverkit), specifically [`USBDriverKit`](https://developer.apple.com/documentation/usbdriverkit) (though this would rule out `sane-backends` using parallel, SCSI, or any other non-USB interface)?
* Maybe port the `TwainSaneInterface` from using `TWAIN.framework` to using `ImageCaptureCore` directly? (It's unclear to me whether `ImageCaptureCore` is only for client applicaitons or if it's for drivers, as well.)

Note that `TwainSaneInterface` is written entirely in C and C++, not Objective-C. The only Objective-C file in the entire project is in `TwainSaneInterface` (though the `VirtualScanner` sample project is written in Objective-C). TWAIN is (as far as I can tell) basically a set of C headers, so any code accessing them would need to accept these. In order to access both TWAIN and Cocoa in the same project, it may be necessary to use [Objective-C++](https://objectivecpp.johnholdsworth.com/intro.html), which is just its own weird, weird beast.

Anyway, I hope this updated commentary is helpful!

— Elsie Hupp ([@elsiehupp](https://github.com/elsiehupp)) January 2022
