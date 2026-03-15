# Command Reference

## lulu-cli list [filter]

List all firewall rules. Optionally filter by keyword (matches key or path).

- No sudo required (read-only)
- Output format: `[key]` header, then one line per rule with UUID, action, addr, port, type

## lulu-cli recent [N]

Show the N most recent block rules, sorted by creation date (newest first). Default: 20.

- No sudo required (read-only)
- Useful for diagnosing connection failures

## lulu-cli add

Add a new firewall rule.

**Required flags:**
- `--key KEY` - signing identity (e.g. `com.apple.curl`) or `*` for global
- `--path PATH` - binary path or `*` for global
- `--action allow|block` - rule action

**Optional flags:**
- `--addr ADDR` - domain, IP, or regex pattern (default: `*`)
- `--port PORT` - port number or `*` for any (default: `*`)
- `--regex` - treat `--addr` as a regex pattern

**Requires sudo.** Run `reload` after.

## lulu-cli delete

Delete rule(s) by key.

**Required flags:**
- `--key KEY` - the rule key

**Optional flags:**
- `--uuid UUID` - delete specific rule. If omitted, deletes ALL rules for the key.

**Requires sudo.** Run `reload` after.

## lulu-cli delete-match

Delete rules matching specific criteria.

**Required flags:**
- `--key KEY` - the rule key

**Optional flags:**
- `--action allow|block` - match by action
- `--addr ADDR` - match by address
- `--port PORT` - match by port

**Requires sudo.** Run `reload` after.

## lulu-cli enable / disable

Toggle a rule's disabled state.

**Required flags:**
- `--key KEY` - the rule key
- `--uuid UUID` - the rule UUID

**Requires sudo.** Run `reload` after.

## lulu-cli reload

Kill the LuLu system extension process. macOS auto-restarts registered system extensions, causing it to reload rules from disk.

- ~8 second gap in filtering during restart
- **Requires sudo**

## Key Concepts

- **key**: Signing identity (e.g. `com.apple.curl`) or binary path for unsigned apps. Use `*` for global rules.
- **action**: `allow` or `block`
- **addr**: Domain, IP, regex pattern, or `*` (any)
- **port**: Port number or `*` (any)
- **type**: `default`, `apple`, `baseline`, `user` (manually created), `passive` (auto-created from blocked connections)
- **Global rules**: key=`*` and path=`*` apply to all applications
