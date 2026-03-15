---
name: lulu-cli
description: >
  Manage LuLu macOS firewall rules. Use when connections are blocked, domains
  need allowing/blocking, or firewall rules need reviewing. Triggers include
  "connection blocked", "allow domain", "firewall rules", "check blocks",
  "lulu", "unblock".
allowed-tools: Bash(lulu-cli:*), Bash(sudo lulu-cli:*)
metadata:
  openclaw:
    emoji: "🔥"
    os: ["darwin"]
    requires:
      bins: ["lulu-cli"]
    install:
      - id: brew
        kind: brew
        formula: "woop/tap/lulu-cli"
        bins: ["lulu-cli"]
        label: "Install lulu-cli (brew)"
---

# LuLu Firewall CLI

CLI for managing [LuLu](https://objective-see.org/products/lulu.html) macOS firewall rules.

Requires: macOS 13+, LuLu installed, `sudo` for write operations.

## Core Workflow

1. **Diagnose**: check what's being blocked
2. **Fix**: add allow rules for legitimate domains
3. **Apply**: reload the firewall extension

```bash
# Check recent blocks
lulu-cli recent 10

# Allow the blocked domain
sudo lulu-cli add --key '*' --path '*' --action allow --addr example.com --port 443
sudo lulu-cli reload
```

## Commands

### List rules
```bash
lulu-cli list              # all rules
lulu-cli list curl         # filter by keyword
lulu-cli list '*'          # global/wildcard rules only
```

### Recent blocks
```bash
lulu-cli recent            # last 20 blocks
lulu-cli recent 5          # last 5 blocks
```

### Add a rule
```bash
# Allow a domain globally (all apps)
sudo lulu-cli add --key '*' --path '*' --action allow --addr example.com --port 443

# Allow with regex (domain + all subdomains)
sudo lulu-cli add --key '*' --path '*' --action allow \
  --addr '^(.+\.)?example\.com$' --port '*' --regex

# Allow for a specific app only
sudo lulu-cli add --key "/usr/bin/curl" --path /usr/bin/curl \
  --action allow --addr example.com --port 443
```

### Delete rules
```bash
# Delete by UUID
sudo lulu-cli delete --key "com.apple.curl" --uuid "UUID-HERE"

# Delete all rules for a key
sudo lulu-cli delete --key "com.apple.curl"

# Delete matching rules
sudo lulu-cli delete-match --key "com.apple.curl" --action block --port 53
```

### Enable/disable
```bash
sudo lulu-cli enable --key '*' --uuid UUID-HERE
sudo lulu-cli disable --key '*' --uuid UUID-HERE
```

### Reload (apply changes)
```bash
sudo lulu-cli reload
```

Always run `reload` after add/delete/enable/disable. The LuLu extension only reads rules at startup. Reload kills the extension (~8s gap in filtering while it restarts).

See [references/commands.md](references/commands.md) for full details.
