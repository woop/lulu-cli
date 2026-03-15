import Foundation

// MARK: - Rule class (mirrors LuLu's Rule.m NSSecureCoding)

@objc(Rule)
class Rule: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    @objc var uuid: String?
    @objc var key: String?
    @objc var pid: NSNumber?
    @objc var path: String?
    @objc var name: String?
    @objc var csInfo: NSDictionary?
    @objc var endpointAddr: String?
    @objc var endpointHost: String?
    @objc var isEndpointAddrRegex: Bool = false
    @objc var endpointPort: String?
    @objc var type: NSNumber?
    @objc var scope: NSNumber?
    @objc var action: NSNumber?
    @objc var isDisabled: NSNumber?
    @objc var creation: Date?
    @objc var expiration: Date?

    override init() { super.init() }

    required init?(coder decoder: NSCoder) {
        super.init()
        key = decoder.decodeObject(of: NSString.self, forKey: "key") as String?
        uuid = decoder.decodeObject(of: NSString.self, forKey: "uuid") as String?
        pid = decoder.decodeObject(of: NSNumber.self, forKey: "pid")
        path = decoder.decodeObject(of: NSString.self, forKey: "path") as String?
        name = decoder.decodeObject(of: NSString.self, forKey: "name") as String?
        csInfo = decoder.decodeObject(of: [NSDictionary.self, NSArray.self, NSString.self, NSNumber.self], forKey: "csInfo") as? NSDictionary
        isEndpointAddrRegex = decoder.decodeBool(forKey: "isEndpointAddrRegex")
        endpointAddr = decoder.decodeObject(of: NSString.self, forKey: "endpointAddr") as String?
        endpointHost = decoder.decodeObject(of: NSString.self, forKey: "endpointHost") as String?
        endpointPort = decoder.decodeObject(of: NSString.self, forKey: "endpointPort") as String?
        type = decoder.decodeObject(of: NSNumber.self, forKey: "type")
        scope = decoder.decodeObject(of: NSNumber.self, forKey: "scope")
        action = decoder.decodeObject(of: NSNumber.self, forKey: "action")
        isDisabled = decoder.decodeObject(of: NSNumber.self, forKey: "isDisabled")
        creation = decoder.decodeObject(of: NSDate.self, forKey: "creation") as Date?
        expiration = decoder.decodeObject(of: NSDate.self, forKey: "expiration") as Date?
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(key, forKey: "key")
        encoder.encode(uuid, forKey: "uuid")
        encoder.encode(pid, forKey: "pid")
        encoder.encode(path, forKey: "path")
        encoder.encode(name, forKey: "name")
        encoder.encode(csInfo, forKey: "csInfo")
        encoder.encode(isEndpointAddrRegex, forKey: "isEndpointAddrRegex")
        encoder.encode(endpointAddr, forKey: "endpointAddr")
        encoder.encode(endpointHost, forKey: "endpointHost")
        encoder.encode(endpointPort, forKey: "endpointPort")
        encoder.encode(type, forKey: "type")
        encoder.encode(scope, forKey: "scope")
        encoder.encode(action, forKey: "action")
        encoder.encode(isDisabled, forKey: "isDisabled")
        encoder.encode(creation, forKey: "creation")
        encoder.encode(expiration, forKey: "expiration")
    }

    var actionString: String {
        switch action?.intValue {
        case 0: return "Block"
        case 1: return "Allow"
        default: return "Unknown(\(action?.intValue ?? -1))"
        }
    }

    var typeString: String {
        switch type?.intValue {
        case 0: return "default"
        case 1: return "apple"
        case 2: return "baseline"
        case 3: return "user"
        case 4: return "passive"
        case 5: return "recent"
        default: return "unknown(\(type?.intValue ?? -1))"
        }
    }
}

// MARK: - Constants

let RULES_FILE = "/Library/Objective-See/LuLu/rules.plist"
let KEY_RULES = "rules"
let KEY_CS_INFO = "signingInfo"

let RULE_STATE_BLOCK: NSNumber = 0
let RULE_STATE_ALLOW: NSNumber = 1
let RULE_TYPE_USER: NSNumber = 3
let ACTION_SCOPE_ENDPOINT: NSNumber = 1

// MARK: - Load/Save

func loadRules(from path: String = RULES_FILE) -> NSMutableDictionary? {
    guard let data = NSData(contentsOfFile: path) as Data? else {
        fputs("Error: cannot read \(path)\n", stderr)
        return nil
    }

    let classes: [AnyClass] = [NSDictionary.self, NSMutableDictionary.self, NSArray.self, NSMutableArray.self, NSString.self, NSNumber.self, NSMutableSet.self, NSDate.self, Rule.self]

    do {
        let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data)
        guard let dict = unarchived as? NSDictionary else {
            fputs("Error: rules file did not decode to dictionary\n", stderr)
            return nil
        }
        return dict.mutableCopy() as? NSMutableDictionary
    } catch {
        fputs("Error: \(error)\n", stderr)
        return nil
    }
}

func saveRules(_ rules: NSDictionary, to path: String = RULES_FILE) -> Bool {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: rules, requiringSecureCoding: true)
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        return true
    } catch {
        fputs("Error saving: \(error)\n", stderr)
        return false
    }
}

// MARK: - Commands

func listRules(_ rules: NSDictionary, filter: String? = nil) {
    let sortedKeys = (rules.allKeys as! [String]).sorted()

    for key in sortedKeys {
        guard let entry = rules[key] as? NSDictionary,
              let ruleArray = entry[KEY_RULES] as? [Rule] else { continue }

        if let f = filter, !key.localizedCaseInsensitiveContains(f) {
            // Check if any rule path matches
            let pathMatch = ruleArray.contains { $0.path?.localizedCaseInsensitiveContains(f) == true }
            if !pathMatch { continue }
        }

        print("[\(key)]")
        for rule in ruleArray {
            let disabled = rule.isDisabled?.boolValue == true ? " [DISABLED]" : ""
            let regex = rule.isEndpointAddrRegex ? " [REGEX]" : ""
            print("  \(rule.uuid ?? "no-uuid") | \(rule.actionString) | addr=\(rule.endpointAddr ?? "*") port=\(rule.endpointPort ?? "*") | type=\(rule.typeString)\(disabled)\(regex)")
            if let p = rule.path, p != key {
                print("    path=\(p)")
            }
        }
    }
}

func addRule(_ rules: NSMutableDictionary, key: String, path: String, action: NSNumber, addr: String, port: String, isRegex: Bool = false) {
    let rule = Rule()
    rule.uuid = UUID().uuidString
    rule.key = key
    rule.path = path
    rule.name = (path as NSString).lastPathComponent
    rule.action = action
    rule.endpointAddr = addr
    rule.endpointPort = port
    rule.isEndpointAddrRegex = isRegex
    rule.type = RULE_TYPE_USER
    rule.scope = ACTION_SCOPE_ENDPOINT
    rule.creation = Date()

    if var entry = rules[key] as? NSMutableDictionary,
       var ruleArray = entry[KEY_RULES] as? NSMutableArray {
        ruleArray.add(rule)
    } else if let entry = rules[key] as? NSDictionary {
        let mutableEntry = entry.mutableCopy() as! NSMutableDictionary
        if let existingRules = mutableEntry[KEY_RULES] as? NSArray {
            let mutableRules = existingRules.mutableCopy() as! NSMutableArray
            mutableRules.add(rule)
            mutableEntry[KEY_RULES] = mutableRules
        } else {
            mutableEntry[KEY_RULES] = NSMutableArray(object: rule)
        }
        rules[key] = mutableEntry
    } else {
        let entry = NSMutableDictionary()
        entry[KEY_RULES] = NSMutableArray(object: rule)
        rules[key] = entry
    }

    print("Added rule \(rule.uuid!) for \(key): \(rule.actionString) \(addr):\(port)")
}

func deleteRule(_ rules: NSMutableDictionary, key: String, uuid: String?) -> Bool {
    guard let entry = rules[key] as? NSDictionary else {
        fputs("Key not found: \(key)\n", stderr)
        return false
    }

    // If no UUID, delete entire key
    if uuid == nil {
        rules.removeObject(forKey: key)
        print("Deleted all rules for key: \(key)")
        return true
    }

    let mutableEntry = entry.mutableCopy() as! NSMutableDictionary
    guard let ruleArray = mutableEntry[KEY_RULES] as? NSArray else { return false }
    let mutableRules = ruleArray.mutableCopy() as! NSMutableArray

    let idx = mutableRules.indexOfObject(passingTest: { obj, _, _ in
        (obj as? Rule)?.uuid == uuid
    })

    if idx == NSNotFound {
        fputs("UUID not found: \(uuid!)\n", stderr)
        return false
    }

    let removed = mutableRules[idx] as! Rule
    mutableRules.removeObject(at: idx)
    print("Deleted rule \(uuid!): \(removed.actionString) \(removed.endpointAddr ?? "*"):\(removed.endpointPort ?? "*")")

    if mutableRules.count == 0 {
        rules.removeObject(forKey: key)
        print("(removed empty key \(key))")
    } else {
        mutableEntry[KEY_RULES] = mutableRules
        rules[key] = mutableEntry
    }

    return true
}

func deleteRuleByMatch(_ rules: NSMutableDictionary, key: String, action: Int?, addr: String?, port: String?) -> Bool {
    guard let entry = rules[key] as? NSDictionary,
          let ruleArray = entry[KEY_RULES] as? NSArray else {
        fputs("Key not found: \(key)\n", stderr)
        return false
    }

    let mutableEntry = entry.mutableCopy() as! NSMutableDictionary
    let mutableRules = ruleArray.mutableCopy() as! NSMutableArray
    var deleted = 0

    for i in stride(from: mutableRules.count - 1, through: 0, by: -1) {
        guard let rule = mutableRules[i] as? Rule else { continue }
        var matches = true
        if let a = action, rule.action?.intValue != a { matches = false }
        if let ad = addr, rule.endpointAddr != ad { matches = false }
        if let p = port, rule.endpointPort != p { matches = false }
        if matches {
            print("Deleting: \(rule.uuid ?? "?") \(rule.actionString) \(rule.endpointAddr ?? "*"):\(rule.endpointPort ?? "*")")
            mutableRules.removeObject(at: i)
            deleted += 1
        }
    }

    if deleted == 0 {
        fputs("No matching rules found\n", stderr)
        return false
    }

    if mutableRules.count == 0 {
        rules.removeObject(forKey: key)
    } else {
        mutableEntry[KEY_RULES] = mutableRules
        rules[key] = mutableEntry
    }

    print("Deleted \(deleted) rule(s)")
    return true
}

func recentBlocks(_ rules: NSDictionary, count: Int = 20) {
    var allBlocks: [(key: String, rule: Rule)] = []

    for key in rules.allKeys as! [String] {
        guard let entry = rules[key] as? NSDictionary,
              let ruleArray = entry[KEY_RULES] as? [Rule] else { continue }
        for rule in ruleArray {
            if rule.action?.intValue == 0 { // BLOCK
                allBlocks.append((key: key, rule: rule))
            }
        }
    }

    // Sort by creation date, newest first
    allBlocks.sort { ($0.rule.creation ?? .distantPast) > ($1.rule.creation ?? .distantPast) }

    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm"

    let shown = allBlocks.prefix(count)
    for (key, rule) in shown {
        let date = rule.creation.map { df.string(from: $0) } ?? "unknown"
        let disabled = rule.isDisabled?.boolValue == true ? " [DISABLED]" : ""
        print("\(date) | \(rule.endpointAddr ?? "*"):\(rule.endpointPort ?? "*") | \(rule.typeString)\(disabled)")
        print("  key=\(key) uuid=\(rule.uuid ?? "?")")
        if let p = rule.path, p != key {
            print("  path=\(p)")
        }
    }
    print("\n\(allBlocks.count) total block rules, showing \(shown.count) most recent")
}

func toggleRule(_ rules: NSMutableDictionary, key: String, uuid: String, enable: Bool) -> Bool {
    guard let entry = rules[key] as? NSDictionary,
          let ruleArray = entry[KEY_RULES] as? NSArray else {
        fputs("Key not found: \(key)\n", stderr)
        return false
    }

    let mutableEntry = entry.mutableCopy() as! NSMutableDictionary
    let mutableRules = ruleArray.mutableCopy() as! NSMutableArray

    for i in 0..<mutableRules.count {
        guard let rule = mutableRules[i] as? Rule, rule.uuid == uuid else { continue }
        rule.isDisabled = enable ? nil : NSNumber(value: 1)
        print("\(enable ? "Enabled" : "Disabled") rule \(uuid): \(rule.actionString) \(rule.endpointAddr ?? "*"):\(rule.endpointPort ?? "*")")
        mutableEntry[KEY_RULES] = mutableRules
        rules[key] = mutableEntry
        return true
    }

    fputs("UUID not found: \(uuid)\n", stderr)
    return false
}

// MARK: - Usage

func usage() {
    let u = """
    Usage: lulu-rules <command> [options]

    Commands:
      list [filter]                       List all rules (optionally filtered)
      recent [N]                          Show N most recent block rules (default 20)
      add --key KEY --path PATH --action allow|block --addr ADDR --port PORT
                                          Add a rule
      delete --key KEY [--uuid UUID]      Delete rule by key and optional UUID
      delete-match --key KEY [--action allow|block] [--addr ADDR] [--port PORT]
                                          Delete rules matching criteria
      enable --key KEY --uuid UUID        Enable a disabled rule
      disable --key KEY --uuid UUID       Disable a rule
      reload                              Restart LuLu extension to reload rules

    Notes:
      - This tool edits /Library/Objective-See/LuLu/rules.plist directly
      - Run 'lulu-rules reload' after changes for them to take effect
      - Requires root (sudo) for write operations
    """
    print(u)
}

// MARK: - Main

let args = CommandLine.arguments

if args.count < 2 {
    usage()
    exit(1)
}

let command = args[1]

switch command {
case "list":
    guard let rules = loadRules() else { exit(1) }
    let filter = args.count > 2 ? args[2] : nil
    listRules(rules, filter: filter)

case "recent":
    guard let rules = loadRules() else { exit(1) }
    let count = args.count > 2 ? (Int(args[2]) ?? 20) : 20
    recentBlocks(rules, count: count)

case "add":
    var key: String?, path: String?, actionStr: String?, addr = "*", port = "*"
    var isRegex = false
    var i = 2
    while i < args.count {
        switch args[i] {
        case "--key": i += 1; key = args[i]
        case "--path": i += 1; path = args[i]
        case "--action": i += 1; actionStr = args[i]
        case "--addr": i += 1; addr = args[i]
        case "--port": i += 1; port = args[i]
        case "--regex": isRegex = true
        default: break
        }
        i += 1
    }
    guard let k = key, let p = path, let a = actionStr else {
        fputs("Required: --key, --path, --action\n", stderr); exit(1)
    }
    let actionNum: NSNumber = (a == "allow") ? RULE_STATE_ALLOW : RULE_STATE_BLOCK
    guard let rules = loadRules() else { exit(1) }
    addRule(rules, key: k, path: p, action: actionNum, addr: addr, port: port, isRegex: isRegex)
    if saveRules(rules) { print("Saved. Run 'lulu-rules reload' to apply.") }
    else { exit(1) }

case "delete":
    var key: String?, uuid: String?
    var i = 2
    while i < args.count {
        switch args[i] {
        case "--key": i += 1; key = args[i]
        case "--uuid": i += 1; uuid = args[i]
        default: break
        }
        i += 1
    }
    guard let k = key else { fputs("Required: --key\n", stderr); exit(1) }
    guard let rules = loadRules() else { exit(1) }
    if deleteRule(rules, key: k, uuid: uuid) {
        if saveRules(rules) { print("Saved. Run 'lulu-rules reload' to apply.") }
        else { exit(1) }
    } else { exit(1) }

case "delete-match":
    var key: String?, actionStr: String?, addr: String?, port: String?
    var i = 2
    while i < args.count {
        switch args[i] {
        case "--key": i += 1; key = args[i]
        case "--action": i += 1; actionStr = args[i]
        case "--addr": i += 1; addr = args[i]
        case "--port": i += 1; port = args[i]
        default: break
        }
        i += 1
    }
    guard let k = key else { fputs("Required: --key\n", stderr); exit(1) }
    let actionNum = actionStr == "allow" ? 1 : actionStr == "block" ? 0 : nil as Int?
    guard let rules = loadRules() else { exit(1) }
    if deleteRuleByMatch(rules, key: k, action: actionNum, addr: addr, port: port) {
        if saveRules(rules) { print("Saved. Run 'lulu-rules reload' to apply.") }
        else { exit(1) }
    } else { exit(1) }

case "enable", "disable":
    let enable = (command == "enable")
    var key: String?, uuid: String?
    var i = 2
    while i < args.count {
        switch args[i] {
        case "--key": i += 1; key = args[i]
        case "--uuid": i += 1; uuid = args[i]
        default: break
        }
        i += 1
    }
    guard let k = key, let u = uuid else { fputs("Required: --key, --uuid\n", stderr); exit(1) }
    guard let rules = loadRules() else { exit(1) }
    if toggleRule(rules, key: k, uuid: u, enable: enable) {
        if saveRules(rules) { print("Saved. Run 'lulu-rules reload' to apply.") }
        else { exit(1) }
    } else { exit(1) }

case "reload":
    // The system extension loads rules from disk only at startup.
    // Killing it causes macOS to auto-restart it (it's a registered sysext).
    print("Killing LuLu system extension to force reload from disk...")
    print("(Requires sudo — macOS will auto-restart the extension)")
    // Find the extension PID and kill -9 it (killall doesn't work, need SIGKILL)
    let pgrep = Process()
    let pgrepPipe = Pipe()
    pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    pgrep.arguments = ["-f", "com.objective-see.lulu.extension"]
    pgrep.standardOutput = pgrepPipe
    try? pgrep.run()
    pgrep.waitUntilExit()

    let pidData = pgrepPipe.fileHandleForReading.readDataToEndOfFile()
    let pidStr = String(data: pidData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").first ?? ""

    guard let pid = Int(pidStr) else {
        fputs("Could not find LuLu extension process\n", stderr)
        exit(1)
    }

    print("Found extension PID \(pid), sending kill -9...")
    let kill = Process()
    kill.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
    kill.arguments = ["kill", "-9", String(pid)]
    try? kill.run()
    kill.waitUntilExit()

    if kill.terminationStatus == 0 {
        print("Done. Extension will auto-restart and reload rules from disk.")
    } else {
        fputs("Failed (need sudo). Run manually:\n  sudo kill -9 \(pid)\n", stderr)
        exit(1)
    }

case "help", "--help", "-h":
    usage()

default:
    fputs("Unknown command: \(command)\n", stderr)
    usage()
    exit(1)
}
