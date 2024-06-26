#!/bin/sh

#set -x

cd `dirname $0`/..

ARGSOKAY=1
if [ -z $1 ]; then
    ARGSOKAY=0
fi
if [ -z $2 ]; then
    ARGSOKAY=0
fi
if [ -z $3 ]; then
    ARGSOKAY=0
fi

if [ "x$ARGSOKAY" = "x0" ]; then
    echo "USAGE: $0 <major> <minor> <patch>" 1>&2
    exit 1
fi

MAJOR="$1"
MINOR="$2"
MICRO="$3"
NEWVERSION="$MAJOR.$MINOR.$MICRO"

echo "Updating version to '$NEWVERSION' ..."

perl -w -pi -e 's/\A(.* version )[0-9.]+/${1}'$NEWVERSION'/;' include/SDL3/SDL.h

# !!! FIXME: This first one is a kinda scary search/replace that might fail later if another X.Y.Z version is added to the file.
perl -w -pi -e 's/(\<string\>)\d+\.\d+\.\d+/${1}'$NEWVERSION'/;' Xcode/SDL/Info-Framework.plist

perl -w -pi -e 's/(Title SDL )\d+\.\d+\.\d+/${1}'$NEWVERSION'/;' Xcode/SDL/pkg-support/SDL.info

perl -w -pi -e 's/(MARKETING_VERSION\s*=\s*)\d+\.\d+\.\d+/${1}'$NEWVERSION'/;' Xcode/SDL/SDL.xcodeproj/project.pbxproj

DYVER=`expr $MINOR \* 100 + 1`
perl -w -pi -e 's/(DYLIB_CURRENT_VERSION\s*=\s*)\d+\.\d+\.\d+/${1}'$DYVER'.0.0/;' Xcode/SDL/SDL.xcodeproj/project.pbxproj

# Set compat to major.minor.0 by default.
perl -w -pi -e 's/(DYLIB_COMPATIBILITY_VERSION\s*=\s*)\d+\.\d+\.\d+/${1}'$DYVER'.0.0/;' Xcode/SDL/SDL.xcodeproj/project.pbxproj

# non-zero patch?
if [ "x$MICRO" != "x0" ]; then
    if [ `expr $MINOR % 2` = "0" ]; then
        # If patch is not zero, but minor is even, it's a bugfix release.
        perl -w -pi -e 's/(DYLIB_CURRENT_VERSION\s*=\s*)\d+\.\d+\.\d+/${1}'$DYVER'.'$MICRO'.0/;' Xcode/SDL/SDL.xcodeproj/project.pbxproj

    else
        # If patch is not zero, but minor is odd, it's a development prerelease.
        DYVER=`expr $MINOR \* 100 + $MICRO + 1`
        perl -w -pi -e 's/(DYLIB_CURRENT_VERSION\s*=\s*)\d+\.\d+\.\d+/${1}'$DYVER'.0.0/;' Xcode/SDL/SDL.xcodeproj/project.pbxproj
        perl -w -pi -e 's/(DYLIB_COMPATIBILITY_VERSION\s*=\s*)\d+\.\d+\.\d+/${1}'$DYVER'.0.0/;' Xcode/SDL/SDL.xcodeproj/project.pbxproj
    fi
fi

perl -w -pi -e 's/\A(project\(SDL[0-9]+ LANGUAGES C VERSION ")[0-9.]+/${1}'$NEWVERSION'/;' CMakeLists.txt

perl -w -pi -e 's/\A(.* SDL_MAJOR_VERSION = )\d+/${1}'$MAJOR'/;' android-project/app/src/main/java/org/libsdl/app/SDLActivity.java
perl -w -pi -e 's/\A(.* SDL_MINOR_VERSION = )\d+/${1}'$MINOR'/;' android-project/app/src/main/java/org/libsdl/app/SDLActivity.java
perl -w -pi -e 's/\A(.* SDL_MICRO_VERSION = )\d+/${1}'$MICRO'/;' android-project/app/src/main/java/org/libsdl/app/SDLActivity.java

perl -w -pi -e 's/(\#define SDL_MAJOR_VERSION\s+)\d+/${1}'$MAJOR'/;' include/SDL3/SDL_version.h
perl -w -pi -e 's/(\#define SDL_MINOR_VERSION\s+)\d+/${1}'$MINOR'/;' include/SDL3/SDL_version.h
perl -w -pi -e 's/(\#define SDL_MICRO_VERSION\s+)\d+/${1}'$MICRO'/;' include/SDL3/SDL_version.h

perl -w -pi -e 's/(FILEVERSION\s+)\d+,\d+,\d+/${1}'$MAJOR','$MINOR','$MICRO'/;' src/core/windows/version.rc
perl -w -pi -e 's/(PRODUCTVERSION\s+)\d+,\d+,\d+/${1}'$MAJOR','$MINOR','$MICRO'/;' src/core/windows/version.rc
perl -w -pi -e 's/(VALUE "FileVersion", ")\d+, \d+, \d+/${1}'$MAJOR', '$MINOR', '$MICRO'/;' src/core/windows/version.rc
perl -w -pi -e 's/(VALUE "ProductVersion", ")\d+, \d+, \d+/${1}'$MAJOR', '$MINOR', '$MICRO'/;' src/core/windows/version.rc

echo "Running build-scripts/test-versioning.sh to verify changes..."
./build-scripts/test-versioning.sh

echo "All done."
echo "Run 'git diff' and make sure this looks correct, before 'git commit'."

exit 0

