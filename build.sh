#!/usr/bin/env bash
# Build the Octatrick firmware image from your own Octatrack OS 1.40C.
#
#   ./build.sh [--as-merged | --pinned] [--build N] [--version V]
#              [--os <path>] [--modules-tag vX.Y]
#
# Default: sambanks/octabam at main (Sam's current tree, with submodules),
#          the four Octatrick wrappers' upstream/ set to the NEWEST tag of
#          timhastie/octatrick-modules (Tim's current modules, whether or
#          not Sam has re-pinned yet); SY DRUM and PROCESSOR LOAD (since
#          2.11) get wrappers made here while octabam has none, and join
#          the octatrick remix.
# --as-merged : exactly Sam's main, octabam's own module pins, no swap.
# --pinned    : the octabam commit in ./octabam.pin (known good) with the
#               newest modules tag.
# --build N   : the build number the unit shows (default 1; bump per flash).
# --version V : the OS version string, up to 10 chars. Default OCTATRK<x.y>
#               from the modules tag; when that is longer than the field's
#               10 characters (a two-digit minor: OCTATRK2.12 is 11), OTRICK<x.y>.
# --os PATH   : your own OCTATRACK_OS1.40C_dist.zip (or the .syx inside it).
#               Without it, octabam's `make os` downloads the zip from
#               Elektron's site and checks its SHA256.
# --modules-tag vX.Y : the octatrick-modules tag to build (default: the
#               newest vX.Y tag, read from GitHub at each run).
#
# Everything lands under ./work (the octabam checkout, toolchain, OS) and
# ./out (the two images). Nothing is written anywhere else. A built image
# contains Elektron's OS: never share it.
set -euo pipefail

OCTABAM_URL=https://github.com/sambanks/octabam.git
MODULES_URL=https://github.com/timhastie/octatrick-modules.git
WRAPPERS=(synth quantizer direct-jump tuner)
# The 2.11 modules: directory, key, the key the remix lists it after.
EXTRA=("sy-drum:SY DRUM:SYNTH MACHINE" "processor-load:PROCESSOR LOAD:TUNER")
# Tags from the old OCTATRICK9 numbering; the x.y scheme restarted at 2.3,
# so these never count as "newest".
LEGACY_TAGS="v9.1"
FLASH_DOC="https://github.com/sambanks/octabam/blob/main/docs/guide/BUILDING.md#5-flash-from-the-card"
KNOWN_ZIP_SHA256=370c55a3dad3996b8e4b46400a205066fdaf185ad4d0255a3a3f835060573ff0

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$HERE/work"
OUT="$HERE/out"
OB="$WORK/octabam"
LOGS="$WORK/logs"

MODE=default
BUILD=1
VERSION=""
OS_PATH=""
TAG_OVERRIDE=""

usage() { sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --as-merged) MODE=as-merged ;;
    --pinned) MODE=pinned ;;
    --build) BUILD="$2"; shift ;;
    --version) VERSION="$2"; shift ;;
    --os) OS_PATH="$2"; shift ;;
    --modules-tag) TAG_OVERRIDE="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$BUILD" =~ ^[0-9]{1,2}$ ]] || { echo "--build takes a one- or two-digit number (got '$BUILD')" >&2; exit 2; }
if [ -n "$VERSION" ] && [ "${#VERSION}" -gt 10 ]; then
  echo "--version is at most 10 characters (got '$VERSION')" >&2; exit 2
fi

say()  { printf '\n== %s\n' "$*"; }
die()  { printf 'build.sh: %s\n' "$*" >&2; exit 1; }

# Homebrew's bin is not on PATH in every shell; the toolchain lives there.
for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH

sha1_of()   { if command -v shasum >/dev/null 2>&1; then shasum -a 1 "$1" | awk '{print $1}'; else sha1sum "$1" | awk '{print $1}'; fi; }
sha256_of() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; else sha256sum "$1" | awk '{print $1}'; fi; }

# ------------------------------------------------------------ prerequisites --
say "prerequisites"
OSNAME="$(uname -s)"
missing=0
need() {  # cmd "how to get it"
  if command -v "$1" >/dev/null 2>&1; then printf '   %-14s %s\n' "$1" "$(command -v "$1")"
  else printf '   %-14s MISSING -- %s\n' "$1" "$2"; missing=1; fi
}
if [ "$OSNAME" = Darwin ]; then
  need git   "xcode-select --install"
  need make  "xcode-select --install"
  need cc    "xcode-select --install"
  need cmake "brew install cmake"
  need brew  "https://brew.sh (octabam's make setup installs binwalk, radare2 and m68k-elf-gcc with it)"
else
  need git   "apt install git"
  need make  "apt install build-essential"
  need cc    "apt install build-essential"
  need cmake "apt install cmake"
  need binwalk "apt install binwalk (octabam's make setup can only brew-install it)"
  need radare2 "apt install radare2 (same)"
  need m68k-elf-as "apt install binutils-m68k-linux-gnu and symlink the m68k-linux-gnu-* tools as m68k-elf-*; see octabam docs/guide/BUILDING.md section 1a (Linux is unverified by octabam itself)"
fi
need curl  "curl (the OS download, unless you pass --os)"
need unzip "unzip"
need xxd   "xxd (vim-common on Linux)"
need python3 "Python 3.10 or newer"
if command -v python3 >/dev/null 2>&1; then
  pyv="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
  python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' \
    || { echo "   python3 is $pyv; the build needs 3.10 or newer"; missing=1; }
fi
if command -v m68k-elf-gcc >/dev/null 2>&1; then
  printf '   %-14s %s\n' m68k-elf-gcc "$(command -v m68k-elf-gcc)"
elif [ "$OSNAME" = Darwin ]; then
  echo "   m68k-elf-gcc   not yet installed; octabam's make setup will brew-install it (with binwalk and radare2)"
fi
command -v uv >/dev/null 2>&1 || echo "   (uv not found: only needed for octabam's emulator and gates, not for this build)"
[ "$missing" -eq 0 ] || die "install the missing tools above, then run again"

# ------------------------------------------------------------------ octabam --
mkdir -p "$WORK" "$OUT" "$LOGS"
say "octabam ($MODE)"
if [ ! -d "$OB/.git" ]; then
  echo "   cloning $OCTABAM_URL -> work/octabam"
  git clone -q --recurse-submodules "$OCTABAM_URL" "$OB"
else
  echo "   updating work/octabam"
  git -C "$OB" fetch -q origin
fi
# build.sh's own edit of the octatrick remix (SY DRUM, PROCESSOR LOAD; below)
# is undone before the tree is checked; any other edit stops the build.
git -C "$OB" checkout -q -- remixes/octatrick/remix.py 2>/dev/null || true
if [ -n "$(git -C "$OB" status --porcelain --untracked-files=no --ignore-submodules)" ]; then
  die "work/octabam has local edits; move them away (or rm -rf work/octabam) and run again"
fi
case "$MODE" in
  pinned)
    PIN="$(tr -d '[:space:]' < "$HERE/octabam.pin")"
    [ -n "$PIN" ] || die "octabam.pin is empty"
    git -C "$OB" cat-file -e "$PIN^{commit}" 2>/dev/null || git -C "$OB" fetch -q origin "$PIN"
    TARGET="$PIN" ;;
  *) TARGET="$(git -C "$OB" rev-parse origin/main)" ;;
esac
git -C "$OB" checkout -q --detach "$TARGET"
git -C "$OB" submodule update -q --init
OB_SHA="$(git -C "$OB" rev-parse --short HEAD)"
echo "   octabam at $OB_SHA: $(git -C "$OB" log -1 --format='%s (%cd)' --date=short)"
[ -f "$OB/remixes/octatrick/remix.py" ] || die "this octabam commit has no remixes/octatrick -- try --pinned"
for w in "${WRAPPERS[@]}"; do
  [ -f "$OB/modules/$w/upstream/$w/manifest.py" ] || die "modules/$w/upstream is not checked out (submodule)"
done
SAM_PIN="$(git -C "$OB/modules/synth/upstream" rev-parse --short HEAD)"
SAM_PIN_TAG="$(git -C "$OB/modules/synth/upstream" describe --tags --exact-match HEAD 2>/dev/null || true)"
echo "   octabam's own octatrick-modules pin: $SAM_PIN${SAM_PIN_TAG:+ ($SAM_PIN_TAG)}"

# ------------------------------------------------------------------ modules --
say "octatrick-modules"
if [ "$MODE" = as-merged ]; then
  MOD_TAG="$SAM_PIN_TAG"; MOD_SHA="$SAM_PIN"
  echo "   as merged: the wrappers stay at Sam's pin ($SAM_PIN${SAM_PIN_TAG:+ = $SAM_PIN_TAG})"
else
  if [ -n "$TAG_OVERRIDE" ]; then
    MOD_TAG="$TAG_OVERRIDE"
  else
    # Newest = the highest vX.Y by number, legacy tags excluded.
    MOD_TAG="$(git ls-remote --tags --refs "$MODULES_URL" \
      | awk '{print $2}' | sed 's#^refs/tags/##' | grep -E '^v[0-9]+\.[0-9]+$' \
      | grep -v -x -F -f <(tr ' ' '\n' <<< "$LEGACY_TAGS") \
      | sed 's/^v//' | sort -t. -k1,1n -k2,2n | tail -1 | sed 's/^/v/')"
    [ -n "$MOD_TAG" ] || die "no vX.Y tag found at $MODULES_URL"
  fi
  MOD_SHA="$(git ls-remote --tags "$MODULES_URL" "refs/tags/$MOD_TAG^{}" "refs/tags/$MOD_TAG" | awk '{print $1}' | tail -1)"
  [ -n "$MOD_SHA" ] || die "tag $MOD_TAG not found at $MODULES_URL"
  # The peeled line (tag^{}) comes last when the tag is annotated.
  for w in "${WRAPPERS[@]}"; do
    sub="$OB/modules/$w/upstream"
    git -C "$sub" cat-file -e "$MOD_SHA^{commit}" 2>/dev/null || git -C "$sub" fetch -q --tags origin
    git -C "$sub" checkout -q --detach "$MOD_SHA"
  done
  MOD_SHA="$(git -C "$OB/modules/synth/upstream" rev-parse --short HEAD)"
  if [ "$MOD_SHA" = "$SAM_PIN" ]; then
    echo "   newest tag $MOD_TAG = $MOD_SHA, the same commit octabam pins"
  else
    echo "   newest tag $MOD_TAG = $MOD_SHA set on all four wrappers (octabam pinned $SAM_PIN${SAM_PIN_TAG:+ = $SAM_PIN_TAG})"
    echo "   if the build refuses below, Sam's wrappers are behind the tag: build with --as-merged meanwhile"
  fi
fi

# SY DRUM and PROCESSOR LOAD: until octabam carries their wrappers, a wrapper
# is made here as octabam's four are (manifest.py re-exporting
# upstream/<dir>/manifest.py; upstream/ = the modules at the same commit),
# and the key joins remixes/octatrick when it is not listed there.
if [ "$MODE" != as-merged ]; then
  for e in "${EXTRA[@]}"; do
    d="${e%%:*}"; rest="${e#*:}"; key="${rest%%:*}"; after="${rest#*:}"
    if [ ! -f "$OB/modules/synth/upstream/$d/manifest.py" ]; then
      echo "   $key: not in octatrick-modules ${MOD_TAG:-$MOD_SHA}; left out"; continue
    fi
    w="$OB/modules/$d"
    if git -C "$OB" ls-files --error-unmatch "modules/$d/manifest.py" >/dev/null 2>&1; then
      sub="$w/upstream"
      git -C "$sub" cat-file -e "$MOD_SHA^{commit}" 2>/dev/null || git -C "$sub" fetch -q --tags origin
      git -C "$sub" checkout -q --detach "$MOD_SHA"
      echo "   $key: octabam's wrapper, upstream at $MOD_SHA"
    else
      mkdir -p "$w"
      [ -d "$w/upstream/.git" ] || git clone -q "$OB/modules/synth/upstream" "$w/upstream"
      git -C "$w/upstream" checkout -q --detach "$MOD_SHA"
      cat > "$w/manifest.py" <<EOF
"""$key -- made by timhastie/octatrick's build.sh while octabam has no wrapper
for it: re-exports upstream/$d/manifest.py (timhastie/octatrick-modules)."""
import pathlib
import runpy

_UPSTREAM = pathlib.Path(__file__).resolve().parent / "upstream" / "$d" / "manifest.py"
MODULE = runpy.run_path(str(_UPSTREAM), run_name="remix_manifest_${d//-/_}")["MODULE"]
EOF
      echo "   $key: wrapper made in work/octabam/modules/$d (upstream at $MOD_SHA)"
    fi
    if ! grep -q "\"$key\"" "$OB/remixes/octatrick/remix.py"; then
      python3 - "$OB/remixes/octatrick/remix.py" "$key" "$after" <<'PY' || die "could not add $key to remixes/octatrick"
import sys
p, key, after = sys.argv[1:4]
s = open(p).read()
a = '"%s",' % after
if s.count(a) != 1:
    sys.exit("remixes/octatrick lists %r %d times" % (after, s.count(a)))
open(p, "w").write(s.replace(a, a + ' "%s",' % key, 1))
PY
      echo "   $key added to remixes/octatrick (undone at the next run)"
    fi
  done
fi
echo "   combining: octabam $OB_SHA + octatrick-modules ${MOD_TAG:-$MOD_SHA}"

# The x.y the files are named by: the version string's, else the tag's.
if [[ "$VERSION" =~ ^(OCTATRK|OTRICK)([0-9]+\.[0-9]+)$ ]]; then
  XY="${BASH_REMATCH[2]}"
elif [[ "$MOD_TAG" =~ ^v([0-9]+\.[0-9]+)$ ]]; then
  XY="${BASH_REMATCH[1]}"
else
  XY="$MOD_SHA"
fi
# The OS version field holds 10 characters; a longer string is refused by the
# firmware tool, which then leaves the stock 1.40C on the unit. OCTATRK<x.y>
# fits up to x.9; from 2.10 the default is the shorter OTRICK<x.y>.
if [ -z "$VERSION" ]; then
  VERSION="OCTATRK$XY"
  [ "${#VERSION}" -le 10 ] || VERSION="OTRICK$XY"
  [ "${#VERSION}" -le 10 ] || VERSION="OCTATRICK"   # not an x.y (a bare commit): pass --version to name it
fi

# ---------------------------------------------------------------- toolchain --
say "make setup (octabam's toolchain into work/octabam/vendor; minutes the first time: tail -f work/logs/setup.log)"
if ! ( cd "$OB" && make setup ) > "$LOGS/setup.log" 2>&1; then
  tail -30 "$LOGS/setup.log"; die "make setup failed; the full log is work/logs/setup.log"
fi
grep -E '^== |^   (vendor/|local patch|binwalk|already built|installing|\[!\])' "$LOGS/setup.log" || true
[ -x "$OB/vendor/elektron-firmware-tool/elektron-firmware-tool" ] \
  || die "make setup did not produce the firmware tool; read work/logs/setup.log"
grep -a -q EFT_EMIT_CONTAINER "$OB/vendor/elektron-firmware-tool/elektron-firmware-tool" \
  || die "the firmware tool was built without octabam's patch; rm -rf work/octabam/vendor/elektron-firmware-tool and run again"

# ----------------------------------------------------------------------- OS --
say "Octatrack OS 1.40C"
SYX="$OB/downloads/extracted/OCTATRACK_OS1.40C.syx"
fresh_os=0
if [ -n "$OS_PATH" ]; then
  [ -f "$OS_PATH" ] || die "--os: no such file: $OS_PATH"
  mkdir -p "$OB/downloads/extracted"
  case "$OS_PATH" in
    *.zip|*.ZIP)
      cp "$OS_PATH" "$OB/downloads/OCTATRACK_OS1.40C_dist.zip"
      got="$(sha256_of "$OB/downloads/OCTATRACK_OS1.40C_dist.zip")"
      echo "   zip sha256 $got"
      [ "$got" = "$KNOWN_ZIP_SHA256" ] || echo "   WARNING: not the zip octabam was verified against ($KNOWN_ZIP_SHA256)"
      unzip -q -o "$OB/downloads/OCTATRACK_OS1.40C_dist.zip" -d "$OB/downloads/extracted" ;;
    *.syx|*.SYX) cp "$OS_PATH" "$SYX" ;;
    *) die "--os takes OCTATRACK_OS1.40C_dist.zip or OCTATRACK_OS1.40C.syx" ;;
  esac
  fresh_os=1
elif [ -f "$SYX" ]; then
  echo "   already in work/octabam/downloads (pass --os to replace it)"
else
  echo "   downloading from Elektron's site (octabam's make os)"
  if ! ( cd "$OB" && make os ) > "$LOGS/os.log" 2>&1; then
    tail -10 "$LOGS/os.log"
    die "the download failed; get OCTATRACK_OS1.40C_dist.zip from Elektron's Octatrack support page yourself and pass --os <zip>"
  fi
  grep -E '^\[fetch\]' "$LOGS/os.log" | grep -v -E 'extracting|done' || true
  fresh_os=1
fi
[ -f "$SYX" ] || die "no OCTATRACK_OS1.40C.syx under work/octabam/downloads/extracted"
if [ "$fresh_os" = 1 ] || [ ! -f "$OB/out/raw/section_3_MAIN_OS.bin" ]; then
  echo "   unpacking (octabam's make recon)"
  ( cd "$OB" && make recon ) > "$LOGS/recon.log" 2>&1 || die "make recon failed; read work/logs/recon.log"
fi
[ -f "$OB/out/raw/section_3_MAIN_OS.bin" ] || die "make recon left no out/raw/section_3_MAIN_OS.bin; read work/logs/recon.log"
echo "   MAIN OS section sha1 $(sha1_of "$OB/out/raw/section_3_MAIN_OS.bin")"

# -------------------------------------------------------------------- image --
say "make image REMIX=octatrick BUILD=$BUILD VERSION=$VERSION"
rm -f "$OB/out/mainos_bus.bin" "$OB/out/OCTATRACK_$VERSION.bin" "$OB/out/OCTATRACK_OS1.40C_$VERSION.syx"
( cd "$OB" && make image REMIX=octatrick BUILD="$BUILD" VERSION="$VERSION" ) > "$LOGS/image.log" 2>&1 \
  || { tail -40 "$LOGS/image.log"; die "the build refused; the full log is work/logs/image.log"; }
grep -E 'bytes changed|placed|modules' "$LOGS/image.log" | tail -5 || true

BIN="$OUT/OCTATRACK_OCTATRICK$XY.bin"
SYXOUT="$OUT/OCTATRACK_OS1.40C_OCTATRICK$XY.syx"
cp "$OB/out/OCTATRACK_$VERSION.bin" "$BIN"
cp "$OB/out/OCTATRACK_OS1.40C_$VERSION.syx" "$SYXOUT"

say "done"
echo "   octabam $OB_SHA + octatrick-modules ${MOD_TAG:-$MOD_SHA}, BUILD $BUILD, version $VERSION"
echo "   bus  sha1 $(sha1_of "$OB/out/mainos_bus.bin")  (work/octabam/out/mainos_bus.bin)"
echo "   card sha1 $(sha1_of "$BIN")  out/$(basename "$BIN")"
echo "   MIDI sha1 $(sha1_of "$SYXOUT")  out/$(basename "$SYXOUT")"
echo
echo "   Flash: copy the card image to the root of the CF card and follow"
echo "   $FLASH_DOC"
echo "   (power-cycle once more after the upgrade). Do not share either file: it contains Elektron's OS."
