# Octatrick

Six additions to the Elektron Octatrack's OS 1.40C, built into one
firmware image with [octabam](https://github.com/sambanks/octabam).

[![Octatrick on a real Octatrack MKI](https://img.youtube.com/vi/1DqUzvs8J3U/maxresdefault.jpg)](https://www.youtube.com/watch?v=1DqUzvs8J3U)

## The modules

- **SYNTH MACHINE** -- FM SYNTH, a two-operator FM synth, is a machine in
  the track's machine list (FUNC + SRC, or SELECT MACHINE TYPE; since 2.10;
  since 2.15 a FLEX track whose sample is named `FMSYNTH*.wav` plays it as a
  sample, and the machine list refuses a choice that would take the active
  Part past the processor's limit, see 2.15). Its PLAYBACK page reads PTCH RATO INDX
  FINE FDBK DEC under the title FM SYNTH; its PLAYBACK SETUP page holds VOIC
  (1 = mono, 2..4 = paraphonic) and CHRD (32 chord shapes, each in four
  inversions), each with its own step and scene locks (since 2.17; before,
  they sat on the LFO page in place of LFO 3, which is back).
  Keys, MIDI IN and the sequencer play it; fingered chords are recorded as
  locks; LEG on the AMP SETUP page is a legato switch (MONO / POLY) and
  GLIDE the slide time, on sample tracks too. Since 2.12 a machine change
  to or from FM SYNTH or SY DRUM resets the track's machine parameters
  (PLAYBACK, PLAYBACK SETUP, AMP, LFO and their SETUP pages) to the new
  machine's init; step and scene locks and the FX slots are kept, as at a
  stock machine change.
- **SCALE QUANTIZER** -- SCALE, ROOT and GLIDE rows in PROJECT > CONTROL >
  SEQUENCER: the PTCH knob, parameter locks and the CHROMATIC keys snap to
  one of 24 scales built on the root. They survive a power cycle. Since
  2.13 MIDI tracks follow SCALE and ROOT too: the NOTE knob, NOTE locks and
  the MIDI CHROMATIC keyboard; since 2.15 so do the chord notes NOT2..4,
  TRAN and the arpeggiator, and rows MIDI 1 SCALE .. MIDI 8 SCALE take a
  MIDI track out of the scale (for a drum machine); since 2.19 what an
  audio track's sequencer plays follows the scale too, and rows AUDIO 1
  SCALE .. AUDIO 8 SCALE take an audio track out of it.
- **DIRECT JUMP** -- CHAIN AFTER gains DIRECT: a pattern chosen while the
  sequencer runs starts at the next step, at the step the old one had
  reached.
- **TUNER** -- hold UP and press TEMPO: a tuner window for the current
  audio track (note, octave, a +-50 cent needle, Hz). TEMPO, YES or NO
  closes it.
- **SY DRUM** (2.11) -- a drum machine in the machine list, the row after
  FM SYNTH: a two-oscillator percussion voice with a sweep and a filter
  opened by the decay, six modes, PTCH MODE WDTH SWEP SPED DEC on its
  PLAYBACK page and a dedicated LFO / S&H (LSPD LDEP WAVE S&H) on its
  PLAYBACK SETUP page, each lockable per step (GRID and LIVE RECORDING; the
  locks are saved beside the project's banks) and, since 2.18, a scene
  target and an LFO destination.
- **PROCESSOR LOAD** (2.11) -- the TEMPO popup shows how busy the
  ColdFire is making audio (`47%`, `!` from 70 %); FUNC held shows the
  longest block.

The `octatrick` remix adds USB MIDI and 20-channel USB audio out (tracks,
MAIN, CUE), USB audio in onto inputs A-D with the USB CROSSBAR, and keeps
the stock effects less SPATIALIZER. On the unit the OS version reads
`OCTATRK<x.y>`, or `OTRICK<x.y>` when the minor has two digits (the field
holds ten characters): 2.21 reads `OTRICK2.21`, 2.22 `OTRICK2.22`.

## What is new in 2.22

Five changes on 2.21, all in the modules; the build, octabam pin and remix
are 2.21's.

- **TRACK and FOLLOW.** SCALE QUANTIZER's sixteen per-track SCALE rows are
  two SEQUENCER rows: TRACK picks AUDIO 1..8 or MIDI 1..8 (not saved) and
  FOLLOW sets that track ON or OFF. The saved bits and project-file lines
  are 2.21's, so a saved project keeps its switches.
- **FOLLOW OFF on an FM SYNTH track** reads the scale as OFF: its keys,
  chords and ROOT are left alone while the other tracks keep the scale.
  Before, only ROOT was skipped and the keys were still snapped.
- **The synth level is the engine's.** An FM SYNTH or SY DRUM track no
  longer follows the GAIN attribute of the sample slot it is assigned to,
  so loading a sample into that slot (or CLEAR SLOT, +12 dB) leaves the
  level alone on the sounding note. A FLEX track on the same slot still
  gets the slot's gain.
- **TUNER reads a track with a DC offset.** The ring's mean is taken off
  before the analysis, so a track whose effects leave an offset larger than
  its swing reads a note instead of holding.
- The synth exports the engine state the quantizer's panel transaction
  reads whenever both are built together, not only with SY DRUM.

Details: the 2.22 entry in
[octatrick-modules](https://github.com/timhastie/octatrick-modules#tags).

## What is new in 2.21

2.21 is the first release since 2.15. The builds 2.16 .. 2.20 between them
were not released on their own; everything they changed is in 2.21.

- **Two fixes from Tim's MKI.** With SCALE set, a chord played on the
  chromatic trig keys of an FM SYNTH track could give different notes on
  repeated presses: keys pressed at nearly the same instant missed the
  scale ROOT, and a key could be paired with another press's pitch. Now
  each key's identity and pitch are taken once, with the ROOT. And after a
  power off and on, the first chord the sequencer played on step 1 sounded
  as one note (saved project or not): the stock queued step 1 before the
  bank's lock table had loaded. That step's locks are now read when it
  plays (SY DRUM's step locks the same way).
- **Setup values across a power-off.** An FM SYNTH VOIC / CHRD edit could
  come back after a power-off without SAVE as the value from before it;
  edited FM SYNTH and SY DRUM PLAYBACK SETUP values now survive it, with
  and without SAVE.
- **The stock DELAY's table tail is stock again.** The FM SYNTH page is a
  DRAM unit; until 2.20 it was pinned at `0x400d24d0`, over 16 bytes the
  stock DELAY reads past its table (found and fixed the same way by
  Jannik Aßfalg in Modwerk #895).
- **From 2.16 .. 2.20.** The load budget: two FM SYNTH tracks fit in a
  Part, and the FM voices are capped so the Part fits beside SY DRUM
  (2.16). LFO 3 is back on FM SYNTH, and VOIC and CHRD are on PLAYBACK
  SETUP with their own step and scene locks, and are LFO destinations; a
  2.15 / 2.16 project migrates at load (2.17). The FM SYNTH PLAYBACK SETUP
  page loses its four unused boxes; VOIC, LEG and SY DRUM's MODE step as
  stock few-valued boxes; a scene on VOIC or CHRD sweeps every value
  between the two sides; the first chord after PLAY plays right; the track
  key pressed twice on an FM SYNTH or SY DRUM track opens the machine list;
  SY DRUM's setup controls are scene targets and LFO destinations; the
  CHROMATIC keyboard marks the note a key sounds, and a MIDI track's
  NOT2..4 step through the scale (2.18). What an audio track's sequencer
  plays follows SCALE and ROOT, with AUDIO 1 SCALE .. AUDIO 8 SCALE rows;
  the setup pages redraw on the SCENE A / B keys (2.19). Following Jan
  Kolkmeier (Modwerk #884), the FM AMP envelope follows LFOs and scenes on
  ATK, HOLD and REL, and an LFO on PTCH moves an FM SYNTH track's pitch 0.2
  semitone per unit of depth, as on FLEX; and the modules' sources carry no
  stock bytes (2.20).

TUNER, DIRECT JUMP and PROCESSOR LOAD build the same code as in 2.15.
Details: the 2.21 entry in
[octatrick-modules](https://github.com/timhastie/octatrick-modules#tags).

## What is new in 2.15

- **A selection guard for FM SYNTH and SY DRUM.** Both render their sound
  on the main processor; with too many of them it runs out of time and
  the unit freezes. The machine lists now refuse a choice that would take
  the active Part past 2 SY DRUM tracks, 1 FM SYNTH track, or FM SYNTH
  with more than 1 SY DRUM track, and say why in the firmware's message
  box (`SY DRUM: 2 MAX`, `FM SYNTH: 1 MAX`, `FM+SY DRUM: LIMIT`); the
  track keeps its machine. The limits come from PROCESSOR LOAD readings on
  Tim's MKI: everything the guard allows stays at or below a worst block
  of about 85 % in an empty project. COPY / PASTE TRACK, the SRC page's
  paste, the Part paste and their undo are guarded the same way (a paste
  past the limits is refused whole, the clipboard kept). A FLEX track
  whose sample is named `FMSYNTH*.wav` or `SYNTH*.wav` no longer becomes
  the synth: it plays the sample, and FM SYNTH is chosen in the machine
  list, so every FM voice is one the guard counted. A project or Part
  saved with more (2.14 and before had no limit) loads and plays as saved.
- **MIDI tracks play in the scale.** With SCALE and ROOT set, the chord
  notes NOT2..4, TRAN, and the arpeggiator's notes and RNGE octaves are
  snapped to the nearest scale note where the sequencer sends them (the
  offsets stay semitones; two chord notes that land on one note sound
  once; nothing hangs), and so is the chord GRID RECORDING previews with a
  [TRIG] key + YES. Rows MIDI 1 SCALE .. MIDI 8 SCALE (ON / OFF, PROJECT >
  CONTROL > SEQUENCER, saved with the project) take a MIDI track out of
  the scale, for a drum machine. With SCALE OFF, or a track's row OFF, the
  track is stock. MIDI IN thru and the auto channel's direct play stay
  stock.
- SY DRUM's recovered-locks message now fits the message box
  (`SY LOCKS RECOVERED`).

TUNER, DIRECT JUMP and PROCESSOR LOAD are 2.14's. Details: the 2.15 entry
in [octatrick-modules](https://github.com/timhastie/octatrick-modules#tags).

## What is new in 2.14

SY DRUM only: a fix found in Tim's test of SY DRUM on his MKI.

- **SY DRUM's step locks survive a power-off without SAVE.** PLAYBACK
  SETUP locks (LSPD LDEP WAVE S&H) edited while the pattern played came
  back without those edits after a power-off with no SAVE PROJECT, while
  the PLAYBACK locks came back. Stock keeps the current bank in
  battery-backed memory and writes its own working files only while the
  sequencer is stopped; SY DRUM's lock files (`sylockNN.work`) were
  written by that same save, so a power-off while playing, or within about
  a second of STOP, found them behind. They are now written while the
  sequencer plays too, at most once every 1.2 s and only while a lock edit
  is unwritten. A lock edited less than about 1.2 s before a power-off can
  still come back without that edit; SAVE PROJECT closes that window.
- **The step locks load beside a missing or damaged stock bank file.**
  When one of the project's stock bank files was missing, cut short or
  damaged (stock shows its message, starts that bank empty and loads the
  project), every bank came back without its SY DRUM step locks. The lock
  files are now read whenever a project loads.

The synth, SCALE QUANTIZER, TUNER, DIRECT JUMP and PROCESSOR LOAD are
2.13's. Details: the 2.14 entry in
[octatrick-modules](https://github.com/timhastie/octatrick-modules#tags).

## What is new in 2.13

SCALE QUANTIZER on MIDI tracks, and a fix:

- **A MIDI track follows SCALE and ROOT.** With a scale on, a MIDI
  track's NOTE knob steps to the next note of the scale built on ROOT, as
  PTCH does on an audio track; NOTE locks do the same (a held trig in GRID
  RECORDING, and LIVE RECORDING); the MIDI CHROMATIC keyboard plays the
  scale from the root: key 1 sounds the root, every key the nearest scale
  note, and the number beside the keyboard names the root ("A 3"). The
  note-off, the arpeggiator's input and the live recorder take the same
  note. NOT2..4, TRAN, the arpeggiator's own notes and MIDI IN stay stock in
  this version; an option for them to follow the scale, and a per-track
  switch that exempts a MIDI track from the scale, are planned. Until
  then program a drum track with SCALE OFF: stored notes are never
  changed, only the knob, the locks and the keys snap while a scale is on. SCALE OFF is stock; there is no new setting and projects are
  unchanged.
- **CHROMATIC on a MIDI track no longer freezes the unit.** Every release
  since 2.9 froze when a MIDI track entered CHROMATIC mode (the keyboard
  drawer's octave hook sat where stock's MIDI branch jumps into it). The
  hook now sits at the drawer's common push, the form Modwerk's bundled
  quantizer has carried since it found the bug (Modwerk #264; thanks to the
  Modwerk contributors).
- **align_check works on current octabam again.** octatrick-modules'
  `tools/align_check.py` (no ColdFire code at an odd address, no jump to
  one) checks the modules as bound to the remix's settings, so it can read
  builds on today's octabam; the 2.13 image passes it.

The synth, SY DRUM, TUNER, DIRECT JUMP and PROCESSOR LOAD are unchanged.
Details: the 2.13 entry in
[octatrick-modules](https://github.com/timhastie/octatrick-modules#tags).

## What is new in 2.12

Two fixes to the FM engine (SYNTH MACHINE; SY DRUM runs on the same
engine), from Tim's test of 2.11 on his MKI:

- **The metronome no longer cuts a held note.** With the metronome on and
  the sequencer playing, a held key or chord was released at the next
  click, and every sequencer note at the first click after it; the engine
  had taken the metronome's click word for a STOP. The click still sounds
  and STOP still ends the voices.
- **A machine change resets the track's machine parameters to init** (the
  rule in the SYNTH MACHINE entry above): no machine parameter is inherited
  from the machine before; locks and FX slots stay, as in the stock
  firmware. 2.10 and 2.11 projects load as they were saved.

Grid steps and played notes were measured at the same level (no level
changed). Details: the 2.12 entry in
[octatrick-modules](https://github.com/timhastie/octatrick-modules#tags).

## On hardware

The first four modules run on Tim's Octatrack MKI (every build since 26
Sep 2026). SY DRUM and PROCESSOR LOAD ran on his MKI on 10 Oct 2026 with the
2.11 module code, as Modwerk test images, with no issues reported (SY DRUM's one remark, the parameters
kept across a machine change, is the 2.12 init). 2.12's two fixes,
2.13's MIDI-track quantizer and 2.14's lock-file fix ran on his MKI on 12
and 13 Oct 2026: the OCTATRICK 2.14 image and the Modwerk test images of
FM Synth 0.1.5 and SY DRUM, with every item of their test sheets reported
working. In 2.14's test the PLAYBACK SETUP locks edited while the pattern
played came back after power-offs without SAVE, and a STATIC track
streaming from the card did not crackle while SY DRUM wrote its lock
files; 2.14's stock-bank-file case is verified on octabam's emulator only.
2.15 (the selection guard and the MIDI tracks' scale) ran on his MKI on
18 Oct 2026, with the guard's limits set from his PROCESSOR LOAD readings
first. The builds 2.16, 2.17 and 2.18 ran on his MKI on 22 and 24 Oct
2026, and what he found there was fixed in the next build; 2.19 and 2.20
were checked on octabam's emulator only. 2.21 ran on his MKI on 29 Oct
2026: the first chord after a power off and on plays as a chord, unsaved
and after SAVE; the chromatic-key chord with a scale and the setup values
across a power-off were checked there on the 2.21 test builds of 27 and 28
Oct, which carry the same code for them; the rest of what 2.16 .. 2.20
changed is in the image but was not tested on it item by item, and the
DELAY fix is checked on the emulator only. 2.22 ran on his MKI on 1 Nov
2026: the SY DRUM level with a sample loaded into its slot, FOLLOW OFF on
an FM SYNTH track with a scale, and a 2.21 project's SCALE OFF rows read as
FOLLOW OFF; the FM SYNTH level, the TRACK and FOLLOW rows and TUNER's DC
case ran the same day on the Modwerk builds of the same code. Nothing is
tried on an MKII yet.

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
(`v2.22` since 1 Nov 2026; so the image carries Tim's current modules even
before octabam re-pins them), makes wrappers for SY DRUM and PROCESSOR LOAD while octabam has none
and adds both to the `octatrick` remix, runs octabam's own `make setup`, downloads OS 1.40C from Elektron's
site (`--os <path>` to use your own copy of `OCTATRACK_OS1.40C_dist.zip`),
and leaves two files in `out/`:

```
out/OCTATRACK_OCTATRICK<x.y>.bin             the card image
out/OCTATRACK_OS1.40C_OCTATRICK<x.y>.syx     the MIDI image
```

Options: `--as-merged` builds exactly Sam's main; `--pinned` builds the
known-good octabam commit in `octabam.pin` (the commit the 2.13, 2.14,
2.15 and 2.21 images were built and checked on); `--build N` sets the build number the unit
shows (bump it each flash); `--version V` the version string (at most ten
characters; the default is `OCTATRK<x.y>`, or `OTRICK<x.y>` when that is
too long); `--modules-tag vX.Y` builds another tag than the newest.
Everything the script makes lives under `work/` and `out/`.

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
  `modules/tuner`, `remixes/octatrick`); SY DRUM's and PROCESSOR LOAD's
  wrappers are made by `build.sh` until octabam carries them.
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
