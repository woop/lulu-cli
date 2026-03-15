# AGENTS.md

Instructions for AI coding agents working on this codebase.

## Overview

Swift CLI that reads/writes LuLu's `rules.plist` (NSKeyedArchiver binary format). macOS only.

## Build

```bash
make build          # swift build -c release
make install        # build + copy to ~/.local/bin/
make clean          # swift package clean
```

## Project Structure

```
Sources/LuLuCLI/main.swift    # Everything lives here (single-file CLI)
Package.swift                  # SwiftPM manifest
Makefile                       # Build/install interface
skills/lulu-cli/               # AI agent skill
```

## Code Style

- Single-file CLI (main.swift). Keep it that way unless it grows significantly.
- CLI flags use `--kebab-case`.
- Error output goes to stderr (`fputs(..., stderr)`), normal output to stdout (`print`).
- All write operations require root; read operations don't.

## Testing

No automated tests currently. The CLI operates on a system plist owned by root, so testing requires either:
- A mock plist file (pass custom path to `loadRules`/`saveRules`)
- Running with sudo on a machine with LuLu installed

## Key Implementation Details

- The `Rule` class mirrors LuLu's Objective-C `Rule.m` with NSSecureCoding.
- Rules are stored in an NSKeyedArchiver binary plist at `/Library/Objective-See/LuLu/rules.plist`.
- The LuLu system extension only reads rules at startup -- `reload` kills it so macOS auto-restarts it.
- Always run `reload` after write operations.

## PR Guidelines

- Update `skills/lulu-cli/SKILL.md` if commands or flags change.
- Update `README.md` with any user-facing changes.
- Test on macOS with LuLu installed before submitting.
