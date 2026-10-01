# Octatrick

Four additions to the Elektron Octatrack's OS 1.40C, built into one
firmware image with [octabam](https://github.com/sambanks/octabam).

[![Octatrick on a real Octatrack MKI](https://img.youtube.com/vi/1DqUzvs8J3U/maxresdefault.jpg)](https://www.youtube.com/watch?v=1DqUzvs8J3U)

## The modules

- **SYNTH MACHINE** -- a FLEX track whose sample is named `FMSYNTH*.wav`
  becomes a two-operator FM synth. Its PLAYBACK page reads PTCH RATO INDX
  FINE FDBK DEC under the title FM SYNTH; the LFO page gains VOIC (1 = mono,
  2..4 = paraphonic) and CHRD (32 chord shapes, each in four inversions).
  Keys, MIDI IN and the sequencer play it; fingered chords are recorded as
  locks; LEG on the AMP SETUP page is a legato switch (MONO / POLY) and
  GLIDE the slide time, on sample tracks too.
- **SCALE QUANTIZER** -- SCALE, ROOT and GLIDE rows in PROJECT > CONTROL >
  SEQUENCER: the PTCH knob, parameter locks and the CHROMATIC keys snap to
  one of 24 scales built on the root. They survive a power cycle.
- **DIRECT JUMP** -- CHAIN AFTER gains DIRECT: a pattern chosen while the
  sequencer runs starts at the next step, at the step the old one had
  reached.
- **TUNER** -- hold UP and press TEMPO: a tuner window for the current
  audio track (note, octave, a +-50 cent needle, Hz). TEMPO, YES or NO
  closes it.

The `octatrick` remix adds USB MIDI and 20-channel USB audio out (tracks,
MAIN, CUE), USB audio in onto inputs A-D with the USB CROSSBAR, and keeps
the stock effects less SPATIALIZER. On the unit the OS version reads
`OCTATRK<x.y>`.

Runs on Tim's Octatrack MKI (every build since 26 Sep 2026); not yet
tried on an MKII.

## Build it

One command builds the image on your own machine from your own copy of
OS 1.40C:

```
git clone https://github.com/timhastie/octatrick
cd octatrick
./build.sh
```

It clones Sam's octabam at `main`, points the four module wrappers at the
newest tag of [octatrick-modules](https://github.com/timhastie/octatrick-modules)
(so the image carries Tim's current modules even before octabam re-pins
them), runs octabam's own `make setup`, downloads OS 1.40C from Elektron's
site (`--os <path>` to use your own copy of `OCTATRACK_OS1.40C_dist.zip`),
and leaves two files in `out/`:

```
out/OCTATRACK_OCTATRICK<x.y>.bin             the card image
out/OCTATRACK_OS1.40C_OCTATRICK<x.y>.syx     the MIDI image
```

Options: `--as-merged` builds exactly Sam's main; `--pinned` builds the
known-good octabam commit in `octabam.pin`; `--build N` sets the build
number the unit shows (bump it each flash); `--version OCTATRKx.y` the
version string. Everything the script makes lives under `work/` and
`out/`.

Prerequisites (the script checks them): on macOS the Xcode Command Line
Tools, [Homebrew](https://brew.sh), Python 3.10+ and `brew install cmake`;
octabam's `make setup` brew-installs the rest (`binwalk`, `radare2`,
`m68k-elf-gcc`). Linux and WSL2: octabam's
[BUILDING.md section 1a](https://github.com/sambanks/octabam/blob/main/docs/guide/BUILDING.md#1a-linux-and-wsl2).
Expect the first run to take a few minutes (the toolchain is built from
source); later runs take a minute.

## Flash it

Follow octabam's guide:
[BUILDING.md, section 5, Flash from the card](https://github.com/sambanks/octabam/blob/main/docs/guide/BUILDING.md#5-flash-from-the-card)
(and section 7 for recovery). Back up your card first, power-cycle once
more after the upgrade, and SAVE the project after changing SCALE, ROOT or
GLIDE.

## Where things live

- The modules' sources: [timhastie/octatrick-modules](https://github.com/timhastie/octatrick-modules)
  (each module's README says what was measured and what was inferred).
- The build system and the `octatrick` remix: [sambanks/octabam](https://github.com/sambanks/octabam)
  (`modules/synth`, `modules/quantizer`, `modules/direct-jump`,
  `modules/tuner`, `remixes/octatrick`).
- An emulator with a virtual front panel: [timhastie/octa-panel](https://github.com/timhastie/octa-panel).

## Credits

- [Sam Banks](https://github.com/sambanks) -- octabam: the build system,
  the ledger, the DRAM platform, the emulators and the gates.
- [markandrus/octemu](https://github.com/markandrus/octemu) -- USB MIDI
  and USB audio out, ported into octabam by Sam.
- Bryan T ([bryantysinger](https://github.com/bryantysinger)) -- USB audio
  in, the USB CROSSBAR, MAIN/CUE alignment and the latency servo, and the
  reverse engineering notes the synth's EMAC arithmetic was written
  against.
- [Maxolydian](https://github.com/mxldyn/octamax) -- octamax, the reverse
  engineering of the OS format, memory map and parameter tables.

## Unofficial

Not affiliated with, endorsed by or supported by Elektron. No firmware is
in this repository or in a build's git history: every image is built on
your machine from your own copy of OS 1.40C, and a built image contains
Elektron's OS, so never share one. Modifying your unit's firmware is
outside Elektron's licence terms and warranty.

## License

[MIT](LICENSE), Tim Hastie 2026, for this repository. octabam is Sam
Banks's under its own MIT licence; Elektron's firmware is Elektron's.
