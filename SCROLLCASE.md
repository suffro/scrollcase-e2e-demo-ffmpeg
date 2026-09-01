[Scrollcase documentation](https://scrollcase.dev/)

# Scrollcase in this project

Scrollcase turns a declarative [scroll](https://scrollcase.dev/reference/scroll) into a signed,
portable [box](https://scrollcase.dev/reference/box-format) for one [target](https://scrollcase.dev/reference/box-format#targets) and one
[runtime](https://scrollcase.dev/reference/scroll#choosing-a-runtime) — `python`, `node`, or `native`, which carries no interpreter. A workspace holds many boxes; `new scroll` asks per box.

## Usual workflow

Run `npm install scrollcase` to install Scrollcase CLI. Then:

1. `scrollcase init`, then `scrollcase new scroll` for your own box
2. `scrollcase add dep <boxId> <name>` and `scrollcase add asset <boxId> <url>` to declare what
   the box contains — the download size and hash are recorded for you
3. `scrollcase lock <boxId>/<targetId>`
4. `scrollcase keygen`
5. `scrollcase build <boxId>/<targetId>`
6. `scrollcase verify <release.json> --self-test` or `scrollcase run <release.json>`

See the [CLI reference](https://scrollcase.dev/reference/cli) and
[signing guidance](https://scrollcase.dev/guides/signing-and-custody). The `consumer-templates/`
files demonstrate the [consumer APIs](https://scrollcase.dev/reference/api) — your application's language, not your box's runtime.

## Node consumer

```sh
npm install scrollcase
npm install --save-dev tsx typescript
npx tsx consumer-templates/run-box.ts
```

## Python consumer

npm does not install the Python consumer. A Python-only application does not need the Node CLI:

```sh
python -m pip install scrollcase-consumer
python consumer-templates/run_box.py
```

## Rust consumer

```sh
cargo add --manifest-path consumer-templates/rust/Cargo.toml scrollcase-consumer
cargo run --manifest-path consumer-templates/rust/Cargo.toml
```

[Scrollcase documentation](https://scrollcase.dev/)
