# 🌀 pi-nix

> **Bring the AI coding agent `pi` into your Nix world — reproducibly, hermetically, and without fighting npm.**

`pi-nix` is an unofficial [Nix flake](https://nixos.wiki/wiki/Flakes) that packages **[pi](https://github.com/badlogic/pi-mono)** — a powerful AI coding agent CLI — so you can install it declaratively on any Unix system, wire it into your NixOS configuration or Home Manager setup, and never worry about `npm install` breaking your environment again.

---

## Why does this exist?

`pi` is a fantastic tool. It gives you an AI pair-programmer that can read files, run shell commands, edit code with surgical precision, and manage multi-turn sessions — all from your terminal. The only catch? It lives inside a JavaScript monorepo and ships through npm.

For Nix users, that's a small but very real friction point. We'd rather:

- ✅ Pin an exact, reproducible version
- ✅ Declare it alongside the rest of our system packages
- ✅ Never run `npm install -g` in anger ever again

So `pi-nix` was born: a flake that takes `pi` from source, threads it through `buildNpmPackage`, tames its native dependencies (yes, `canvas` pulls in Cairo and friends), patches out the bits that need network access at build time, and delivers a clean, self-contained `pi` binary ready to drop into any Nix-managed environment.

---

## Features

- 📦 **Hermetic build** — fetches `pi-mono` from GitHub at a pinned revision with a verified hash
- 🔧 **Native deps handled** — Cairo, Pango, libjpeg, giflib, librsvg, and Pixman are all wired in automatically
- 🛠️ **Runtime tools bundled** — `ripgrep`, `fd`, and `git` are injected into `pi`'s `PATH` so its built-in tools work out of the box
- 🧩 **NixOS overlay included** — expose `pi` as `pkgs.pi` across your entire system config with a single line
- 🌍 **Multi-platform** — builds for all default `flake-utils` systems (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`)

---

## Quick start

### Run without installing

```bash
nix run github:takinbo/pi-nix
```

### Install into your profile

```bash
nix profile install github:takinbo/pi-nix
```

### Try it in a temporary shell

```bash
nix shell github:takinbo/pi-nix
pi --help
```

---

## NixOS / Home Manager integration

### As a flake input

Add `pi-nix` to your `flake.nix` inputs:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  pi-nix.url  = "github:takinbo/pi-nix";
};
```

### Using the overlay (recommended)

Apply the overlay so `pi` is available as `pkgs.pi` everywhere:

```nix
# flake.nix (NixOS configuration)
outputs = { nixpkgs, pi-nix, ... }: {
  nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      {
        nixpkgs.overlays = [ pi-nix.overlays.default ];
        environment.systemPackages = [ pkgs.pi ];
      }
    ];
  };
};
```

### Home Manager

```nix
{ inputs, pkgs, ... }: {
  nixpkgs.overlays = [ inputs.pi-nix.overlays.default ];
  home.packages = [ pkgs.pi ];
}
```

### Direct package reference (no overlay)

```nix
environment.systemPackages = [
  pi-nix.packages.${system}.pi
];
```

---

## What is `pi`?

`pi` is an AI coding agent that runs in your terminal, built by [@badlogic](https://github.com/badlogic). It exposes four core tools to its underlying LLM:

| Tool    | What it does                                              |
|---------|-----------------------------------------------------------|
| `read`  | Read files and images with offset/limit support           |
| `bash`  | Execute shell commands and capture their output           |
| `edit`  | Make precise, targeted replacements inside existing files |
| `write` | Create new files or fully overwrite existing ones         |

On top of that, `pi` supports session management, prompt templates, themes, custom extensions, and pluggable AI providers — making it a full-featured agentic development environment inside a single CLI binary.

Learn more: [pi-mono on GitHub](https://github.com/badlogic/pi-mono)

---

## Versioning

This flake currently packages **pi `v0.70.2`**. The pinned source hash and npm deps hash are both recorded in `flake.nix` and `flake.lock` for fully reproducible builds.

To update to a newer version of `pi`, bump the `version`, `rev`, `hash`, and `npmDepsHash` fields in `flake.nix` accordingly.

---

## Development

A `devShell` is included for anyone who wants to hack on this flake:

```bash
nix develop
```

This drops you into a shell with Node.js 22, `ripgrep`, `fd`, and `git` available.

---

## Credits

This flake is based on the original work by **[@blmarket](https://github.com/blmarket)**, who first figured out how to wrangle `pi-mono` into a working Nix derivation. His gist — [*"Nix flake for pi - an AI coding agent from pi-mono"*](https://gist.github.com/blmarket/a43d4aebd15533ddc73b8939eb2e30ed) — laid the foundation: the `buildNpmPackage` structure, the native dependency list, the `preBuild` patch to skip network-dependent steps, and the `makeWrapper` approach for bundling runtime tools. This repository builds on that foundation with an added overlay, a pinned newer version, and this documentation.

Many thanks to [@blmarket](https://github.com/blmarket) for doing the hard yards first. 🙏

---

## License

The packaging code in this repository is released into the public domain (or [MIT](https://opensource.org/licenses/MIT), your pick). `pi` itself is licensed under the [MIT License](https://github.com/badlogic/pi-mono/blob/main/LICENSE) by its original authors.
