#!/usr/bin/env bash
# Packages the Linux release bundle as .deb, .rpm and AppImage.
#
#   flutter build linux --release
#   linux/packaging/build.sh
#
# Writes dist/snag-linux-x64.{deb,rpm,AppImage}. Needs nfpm, appimagetool
# and ImageMagick (convert) on PATH.
set -euo pipefail

cd "$(dirname "$0")/../.."
APP_ID=ir.salehtz.snag
BUNDLE=build/linux/x64/release/bundle
WORK=build/linux/packaging

if [ ! -x "$BUNDLE/snag" ]; then
  echo "No release bundle at $BUNDLE. Run: flutter build linux --release" >&2
  exit 1
fi

# 0.1.0+1 -> 0.1.0; nfpm reads it from the environment.
VERSION=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
export VERSION

rm -rf "$WORK"
mkdir -p "$WORK" dist
convert assets/icon/icon.png -resize 512x512 "$WORK/$APP_ID.png"

nfpm package -f linux/packaging/nfpm.yaml -p deb -t dist/snag-linux-x64.deb
nfpm package -f linux/packaging/nfpm.yaml -p rpm -t dist/snag-linux-x64.rpm

# AppImage: the bundle as-is, with the launcher, desktop entry and icon at
# its root. Flutter finds lib/ and data/ next to the real executable.
APPDIR="$WORK/AppDir"
cp -r "$BUNDLE" "$APPDIR"
ln -s snag "$APPDIR/AppRun"
cp "linux/packaging/$APP_ID.desktop" "$WORK/$APP_ID.png" "$APPDIR/"
ARCH=x86_64 appimagetool --no-appstream "$APPDIR" dist/snag-linux-x64.AppImage
