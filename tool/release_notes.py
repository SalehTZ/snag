#!/usr/bin/env python3
"""Writes the GitHub release notes for a tag.

    python3 tool/release_notes.py --check v0.1.0        # before building
    python3 tool/release_notes.py v0.1.0 dist > notes.md

The notes are the version's CHANGELOG.md section, then a "which file do I
need" table, help for macOS and APK verification, and SHA-256 checksums,
which also go to dist/SHA256SUMS.txt. --check only confirms that pubspec.yaml
and CHANGELOG.md are ready for the tag, so a release fails in seconds instead
of after every platform has built.
"""
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = "https://github.com/SalehTZ/snag"

# (who it's for, file). Every file must be in dist/ when publishing.
DOWNLOADS = [
    ("Android, most phones", "snag-android-arm64-v8a.apk"),
    ("Android, older phones", "snag-android-armeabi-v7a.apk"),
    ("Android, x86_64 (emulators, some Chromebooks)", "snag-android-x86_64.apk"),
    ("Windows 10 or 11 (unzip, run `snag.exe`)", "snag-windows-x64.zip"),
    ("macOS, Apple silicon or Intel", "snag-macos.dmg"),
    ("macOS, as a zip", "snag-macos.zip"),
    ("Linux, any distribution (`chmod +x`, then run it)", "snag-linux-x64.AppImage"),
    ("Debian, Ubuntu, Mint", "snag-linux-x64.deb"),
    ("Fedora, openSUSE", "snag-linux-x64.rpm"),
    ("Linux, plain bundle (extract, run `./snag`)", "snag-linux-x64.tar.gz"),
]


def fail(msg: str) -> None:
    sys.exit(f"release notes: {msg}")


def version_of(tag: str) -> str:
    if not re.fullmatch(r"v\d+\.\d+\.\d+([-.+]\w+)*", tag):
        fail(f"{tag!r} is not a version tag like v1.2.3")
    version = tag[1:]
    pubspec = re.search(r"^version:\s*([^+\s]+)", (ROOT / "pubspec.yaml").read_text(), re.M)
    if not pubspec or pubspec.group(1) != version:
        fail(f"tag is {tag} but pubspec.yaml has version {pubspec and pubspec.group(1)}; bump one of them")
    return version


def changelog(version: str) -> str:
    text = (ROOT / "CHANGELOG.md").read_text()
    head = re.search(rf"^## \[?{re.escape(version)}(?=[\]\s]|$).*$", text, re.M)
    if not head:
        fail(f"CHANGELOG.md has no '## {version}' section; add one before tagging")
    nxt = re.search(r"^## ", text[head.end():], re.M)
    body = text[head.end(): head.end() + nxt.start() if nxt else len(text)].strip()
    if not body:
        fail(f"the '## {version}' section of CHANGELOG.md is empty")
    return body


def apk_fingerprint() -> str:
    """The release certificate's SHA-256, as published in README.md."""
    found = set(re.findall(r"\b(?:[0-9A-F]{2}:){31}[0-9A-F]{2}\b", (ROOT / "README.md").read_text()))
    if len(found) != 1:
        fail("expected exactly one APK certificate SHA-256 in README.md")
    return found.pop()


def checksums(dist: Path) -> str:
    missing = [f for _, f in DOWNLOADS if not (dist / f).is_file()]
    if missing:
        fail(f"missing from {dist}: {', '.join(missing)}")
    lines = [
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}"
        for p in sorted(dist.iterdir())
        if p.is_file() and p.name != "SHA256SUMS.txt"
    ]
    sums = "\n".join(lines) + "\n"
    (dist / "SHA256SUMS.txt").write_text(sums)
    return sums


def notes(tag: str, dist: Path) -> str:
    version = version_of(tag)
    download = f"{REPO}/releases/download/{tag}"
    rows = "\n".join(f"| {who} | [{f}]({download}/{f}) |" for who, f in DOWNLOADS)
    return f"""{changelog(version)}

### Download

| For | File |
|---|---|
{rows}

On desktop, Snag fetches the official yt-dlp, ffmpeg and Deno the first time it runs, into its own folder. On Android everything is built in.

<details>
<summary><b>macOS says Snag can't be opened</b></summary>

Snag isn't notarized by Apple yet. Drag Snag from the DMG into Applications and open it once. Then go to **System Settings > Privacy & Security** and click **Open Anyway**. You only need to do this once.
</details>

<details>
<summary><b>Check that an APK really comes from us</b></summary>

Every Android release is signed with the same key. With `apksigner` from the Android SDK build-tools:

```bash
apksigner verify --print-certs snag-android-arm64-v8a.apk
```

The certificate's SHA-256 digest must be:

```
{apk_fingerprint()}
```
</details>

<details>
<summary><b>SHA-256 checksums</b></summary>

Also attached as `SHA256SUMS.txt`. Check your download with `sha256sum -c SHA256SUMS.txt --ignore-missing`.

```
{checksums(dist).rstrip()}
```
</details>

[فارسی: راهنمای دانلود و نصب]({REPO}/blob/main/README.fa.md)
"""


def main(args: list[str]) -> None:
    if len(args) == 2 and args[0] == "--check":
        version = version_of(args[1])
        changelog(version)
        apk_fingerprint()
        print(f"ready to release {args[1]}")
    elif len(args) == 2:
        sys.stdout.write(notes(args[0], Path(args[1])))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
