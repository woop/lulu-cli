# lulu-cli

Manage [LuLu](https://objective-see.org/products/lulu.html) firewall rules from the command line.

[LuLu](https://objective-see.org/products/lulu.html) is a free, open-source macOS firewall that blocks unknown outgoing connections. It has a GUI, but no way to manage rules programmatically. This CLI fills that gap -- useful for automation, scripting, and especially for AI agents that need to manage their own network access.

## Install

```bash
# From source (requires macOS 13+ and Swift)
git clone https://github.com/woop/lulu-cli
cd lulu-cli
make install    # builds and copies to ~/.local/bin/
```

## Quick Start

```bash
# What's being blocked?
lulu-cli recent 5
```
```
2026-03-15 09:12 | api.example.com:443 | passive
  key=com.apple.curl uuid=A1B2C3D4-...
2026-03-15 09:10 | cdn.example.com:443 | passive
  key=org.nodejs.node uuid=E5F6G7H8-...

2 total block rules, showing 2 most recent
```

```bash
# Allow it
sudo lulu-cli add --key '*' --path '*' --action allow --addr api.example.com --port 443
sudo lulu-cli reload
```

That's the core loop: check blocks, add allows, reload.

## Commands

All write operations require `sudo`. Always run `reload` after changes.

```
lulu-cli list [filter]           List rules (optionally filter by keyword)
lulu-cli recent [N]              Show N most recent blocks (default: 20)

sudo lulu-cli add                Add a rule
  --key KEY                        Signing identity or '*' for global
  --path PATH                     Binary path or '*' for global
  --action allow|block            Rule action
  --addr ADDR                     Domain, IP, or '*' for any (default: '*')
  --port PORT                     Port or '*' for any (default: '*')
  --regex                         Treat --addr as regex

sudo lulu-cli delete             Delete rules
  --key KEY                        Required
  --uuid UUID                     Specific rule (omit to delete all for key)

sudo lulu-cli delete-match       Delete rules matching criteria
  --key KEY                        Required
  --action allow|block             Optional filter
  --addr ADDR                      Optional filter
  --port PORT                      Optional filter

sudo lulu-cli enable|disable     Toggle a rule
  --key KEY --uuid UUID

sudo lulu-cli reload             Restart LuLu extension to apply changes
```

## How It Works

LuLu stores rules in `/Library/Objective-See/LuLu/rules.plist` using NSKeyedArchiver binary format. This CLI reads and writes that file directly, using the same serialization format as LuLu's Objective-C codebase.

The LuLu system extension only loads rules at startup. After changes, `reload` kills the extension process and macOS auto-restarts it (takes ~8 seconds). There's a brief gap in filtering during the restart.

## AI Agent Skill

This repo ships with an [AgentSkills](https://agentskills.io)-compatible skill in [`skills/lulu-cli/`](skills/lulu-cli/SKILL.md).

**OpenClaw:** install via [ClawHub](https://clawhub.com) or copy the skill directory.

**Claude Code:** the `.claude-plugin/` manifest makes it installable from the marketplace.

The skill teaches AI agents when and how to use lulu-cli, so they can diagnose blocked connections and fix them without human intervention.

## License

MIT
