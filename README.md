# Ship ffmpeg in a signed box with no interpreter

Some programs are miserable to install and worse to reproduce. **ffmpeg** is the archetype: a large
compiled binary with a long tail of codec libraries, where "just install ffmpeg" means a different
version on every machine and a different answer from each.

This demo packs one — pinned, with everything it links against — into a signed box that starts a
binary and carries **no interpreter at all**. That is the `native` runtime.

<big> **Follow these steps to create, sign, build, verify and run the box:** </big>

## 1. Install the Scrollcase CLI

```sh
npm install -g scrollcase
```

## 2. Initialise the project

```sh
scrollcase init
```

| It asks | Answer |
| --- | --- |
| Include the runnable example? | `n` |
| Include the consumer templates? | `n` |
| Install pixi and conda-pack into …/.scrollcase/toolchain? | `Y` (just press Enter) |

The last question **only appears when they are missing**, which in a fresh Codespace they are. On a
machine that already has both, `init` says so instead — and warns if a newer pixi has been released,
because `new scroll` pins the one it finds and `build` then refuses any other for that scroll.

> Both tools land **inside the project**, under `.scrollcase/toolchain/`. Nothing is installed
> system-wide and nothing is added to `PATH`.

## 3. Create the scroll

```sh
scrollcase new scroll
```

| It asks | Answer |
| --- | --- |
| Which **target**? | `linux-x86_64-cpu` |
| Which **runtime**? | `native` |
| **Box ID** | `transcode-demo` |
| **Upstream revision** | `ffmpeg-9-conda-forge` |
| **Asset base URL** | *press Enter to skip* |
| Which **binary source**? | `a program the environment provides` |
| **Path inside the box** | `venv/bin/ffmpeg` |

Two things this runtime does differently.

**No execution-kind question.** `native` defines exactly one — `native-binary` — and a menu of one
is not a question, so it is settled without asking.

**It asks where the binary comes from.** A `native` box has two origins, and they are not the same
thing. *A program the environment provides* means the dependency solve installs it — nothing of
yours is copied into the box, and the scroll simply names where it lands. *A compiled binary in this
project* means you built it and keep it in the repo, and the build copies it in. This demo packages
ffmpeg, so it is the first.

A box may also fix arguments its entry point always gets, before anything a caller passes:
`--default-args -hide_banner` on this command, or a JSON array for several
(`--default-args '["-a", "-b"]'`). Skipped here — hiding ffmpeg's banner is not worth a step of its
own, and seeing the banner in the output below is no loss.

### 3a. Add the dependency

```sh
scrollcase add dep transcode-demo ffmpeg --version "9.*"
```

A `native` box still has a dependency solve and still gets a licence inventory. "No interpreter"
does not mean "no dependencies" — it means nothing in `venv/` is *started* to run the box.

### 3b. Declare the self-test

A `native` box has no module system, so `selfTest.imports` means nothing to it and is refused. It
proves itself by **running its own execution**, and each probe is one command:

```sh
scrollcase add command transcode-demo -- -version

scrollcase add command transcode-demo -- \
  -f lavfi -i "testsrc=duration=1:size=320x240:rate=10" -c:v libx264 -f null -

scrollcase add command transcode-demo --expect-exit-code 254 -- \
  -i no-such-input.mp4 -f null -
```

The arguments come after `--`, so they are taken byte for byte and a leading `-version` is never
mistaken for one of Scrollcase's own flags. The first real probe also replaces the empty placeholder
`new scroll` left behind.

Three probes, and each is doing work:

- `-version` proves the binary starts and its libraries loaded.
- The second **runs a real encode**: a test pattern synthesised by `lavfi`, pushed through
  `libx264`, discarded. A box whose codecs did not relocate fails the build here. No sample video
  ships to make this possible — ffmpeg generates its own input.
- The third proves the failure path, and `254` is not a typo. ffmpeg reports the negative C error
  number for a missing file; `ENOENT` is 2, and an exit status is one byte, so `-2` arrives as 254.
  **A self-test asserts the binary's real contract, not a convention** — this value was measured
  against a built box, after a first attempt expecting `1` failed. Because it is a real failure,
  every `build` and every `verify --self-test` from here on prints a real ffmpeg error; step 6 shows
  what it looks like.

## 4. Lock and audit

```sh
scrollcase lock transcode-demo/linux-x86_64-cpu
scrollcase audit transcode-demo/linux-x86_64-cpu --write
```

Read the audit summary when it prints. Around 90 packages, and roughly a fifth of them are
GPL-family — ffmpeg itself, `x264` and `x265` at GPL-2.0-or-later. **Anyone redistributing this box
needs to know that before they ship it**, which is the whole reason the inventory is derived from
the lock rather than remembered.

## 5. Commit

```sh
git add . && git commit -m "Package ffmpeg"
```

Scrollcase refuses to build from a dirty tree: a box records the commit it came from, and that
record would otherwise be a lie. This Codespace has no remote, so the commit stays here.

## 6. Sign and build

```sh
scrollcase keygen
scrollcase build transcode-demo/linux-x86_64-cpu --asset-base-url https://assets.example.org/boxes
```

Expect a few minutes and a few hundred megabytes. You will see the real encode scroll past — that is
the self-test, running before anything is signed.

> **It ends with an ffmpeg error, and the error is the point.** The last thing the self-test prints
> is this:
>
> ```
> [in#0 @ 0x55b3ed018380] Error opening input: No such file or directory
> Error opening input file no-such-input.mp4.
> Error opening input files: No such file or directory
> ```
>
> That is the third probe from step 3b, asking for a file that does not exist on purpose and getting
> the answer it declared: ffmpeg exits `254`, so the probe **passes**. Scrollcase does not filter or
> swallow a probe's output — you see exactly what the box printed, because a self-test that hides
> what the binary said is a self-test you cannot debug. A probe that genuinely fails looks different:
> the build stops there, nothing is signed, and the final line is Scrollcase's own, naming the status
> it got and the one it wanted (`… exited with status 1 (expected 254)`).

## 7. Verify

```sh
scrollcase verify .scrollcase/dist/boxes/transcode-demo/1.0.0/linux-x86_64-cpu/*.release.json --self-test
```

`--self-test` runs those same three probes again, this time against the archive that was signed
rather than the payload the build assembled — so the ffmpeg error above scrolls past a second time,
for the same reason, and the run still ends in `Verified transcode-demo 1.0.0
(linux-x86_64-cpu)`. Without the flag,
`verify` checks the signature, the archive's size and hash and the manifest, and never starts the
binary at all.

## ✓ Run it

```sh
R=.scrollcase/dist/boxes/transcode-demo/1.0.0/linux-x86_64-cpu/*.release.json

scrollcase run $R -- -version

scrollcase run $R -- -f lavfi -i "testsrc=duration=2:size=640x480:rate=25" \
  -c:v libx264 -pix_fmt yuv420p /tmp/out.mp4

ls -lh /tmp/out.mp4
```

The second command writes a real MP4 **outside** the box, and that is worth noticing: `run` extracts
to a temporary directory and deletes it on exit, so anything the box produces has to go somewhere
the caller names. An application that runs a box repeatedly extracts it durably through a consumer
API instead.

## What this demo shows

**A `native` box starts one binary and nothing else.** There is no script in between. What it runs
is fixed by the scroll, signed into the release, and cannot be changed by whoever holds the box
afterwards — which is the difference between shipping a tool and shipping a tool somebody can
repoint.

**"No interpreter" is not "no dependencies".** The lock is the largest part of this box.

**Check what a program *is* before packing it.** Scrollcase does not repair a binary's recorded
library paths, so a program that finds its parts through an absolute path baked in at build time
will not relocate. `file venv/bin/<program>` answering `ELF 64-bit executable` is what you want; a
shell wrapper is the warning sign. The self-test catches it either way, before signing.

---

Full documentation: **https://scrollcase.dev** — [the scroll](https://scrollcase.dev/reference/scroll), [the `native` runtime](https://scrollcase.dev/reference/scroll#choosing-a-runtime), [the box format](https://scrollcase.dev/reference/box-format), [the CLI](https://scrollcase.dev/reference/cli).
