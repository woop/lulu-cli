# lulu-cli

A command-line interface for managing [LuLu](https://objective-see.org/products/lulu.html) macOS firewall rules. Read, add, delete, enable/disable rules, and reload the firewall extension -- all from the terminal.

Designed for AI agents that need programmatic firewall control, but works great as a standalone tool too.

## Requirements

- macOS 13+
- [LuLu](https://objective-see.org/products/lulu.html) installed
- `sudo` access for write operations and reload

## Install

```bash
# Homebrew
brew install woop/tap/lulu-cli

# From source
git clone https://github.com/woop/lulu-cli
cd lulu-cli
make install
```

## Quick Start

```bash
# List all rules
lulu-cli list

# List rules matching a filter
lulu-cli list curl

# Show recent blocks
lulu-cli recent 10

# Allow a domain globally
sudo lulu-cli add --key '*' --path '*' --action allow --addr example.com --port 443
sudo lulu-cli reload

# Allow a domain with regex (including subdomains)
sudo lulu-cli add --key '*' --path '*' --action allow --addr '^(.+\.)?example\.com$' --port '*' --regex
sudo lulu-cli reload

# Delete a rule
sudo lulu-cli delete --key "com.apple.curl" --uuid "UUID-HERE"
sudo lulu-cli reload
```

## Commands

| Command | Description |
|---------|-------------|
| `list [filter]` | List all rules, optionally filtered by keyword |
| `recent [N]` | Show N most recent block rules (default 20) |
| `add` | Add a firewall rule |
| `delete` | Delete rule(s) by key and optional UUID |
| `delete-match` | Delete rules matching criteria |
| `enable` | Enable a disabled rule |
| `disable` | Disable a rule |
| `reload` | Restart LuLu extension to apply changes |

Run `lulu-cli help` for full usage details.

## How It Works

LuLu stores firewall rules in `/Library/Objective-See/LuLu/rules.plist` using NSKeyedArchiver binary format. This CLI reads and writes that file directly using the same serialization format as LuLu.

The LuLu system extension only reads rules at startup, so after any changes you need to run `lulu-cli reload` which kills the extension process (macOS auto-restarts it within ~8 seconds).

## AI Agent Skill

This repo includes an AI agent skill in `skills/lulu-cli/`. Install it in [OpenClaw](https://openclaw.ai) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code) to let AI agents manage firewall rules automatically.

## License

MIT
