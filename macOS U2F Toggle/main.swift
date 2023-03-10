//
//  main.swift
//  macOS U2F Enabler
//
//  Created by Олег Сазонов on 12.01.2023.
//

import Foundation

class SystemAuthData {
    init() {
        self.pamLibLocationInOpt = {
            var retval: String? = nil
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(filePath: "/bin/bash")
            process.arguments = ["-c", "find /opt -name pam_u2f.so"]
            process.standardOutput = pipe
            do {
                try process.run()
                if let out = String(data: pipe.fileHandleForReading.availableData, encoding: .utf8) {
                    out.split(separator: "\n").forEach { line in
                        if !line.contains("find: /opt: No such file or directory") {
                            retval = String(out.replacingOccurrences(of: "\n", with: ""))
                        }
                    }
                }
            } catch let error {
                NSLog(error.localizedDescription)
            }
            return retval
        }()
        
        self.sudoContents = {
                let data = FileManager.default.contents(atPath: "/etc/pam.d/sudo")
                let sudoText = String(data: data!, encoding: .utf8)!
                var state: task = .disable
                sudoText.split(separator: "\n").forEach { line in
                    if line.contains(pamLibLocationInOpt!) {
                        state = .enable
                    }
                }
                return (contents: sudoText, state: state)
        }()
        
        self.screensaverContents = {
                let data = FileManager.default.contents(atPath: "/etc/pam.d/screensaver")
                let sudoText = String(data: data!, encoding: .utf8)!
                var state: task = .disable
                sudoText.split(separator: "\n").forEach { line in
                    if line.contains(pamLibLocationInOpt!) {
                        state = .enable
                    }
                }
                return (contents: sudoText, state: state)
        }()
        
        self.enabled = {
            let mutualState = (sudo: sudoContents.state, screensaver: screensaverContents.state)
            switch mutualState {
            case (.enable, .enable) : return .both
            case (.enable, .disable) : return .sudo
            case (.disable, .enable) : return .screensaver
            case (.disable, .disable) : return .neither
            }
        }()
    }
    var pamLibLocationInOpt: String? = nil

    var sudoContents: (contents: String, state: task) = ("", .disable)
    var screensaverContents: (contents: String, state: task) = ("", .disable)
    var enabled: whatIsEnabled = .neither

    func notInstalled() -> Bool {
        let path = URL.homeDirectory.path(percentEncoded: false) + ".config/Yubico/u2f_keys"
        return !FileManager.default.isReadableFile(atPath: path) || pamLibLocationInOpt == nil
    }

    func inRange(_ i: Int, rang: ClosedRange<Int>) -> Bool {
        return i >= rang.lowerBound && i <= rang.upperBound
    }

        func edit(_ task: task, _ file: file, _ password: String) {
            let f = file == .screensaver ? screensaverContents : sudoContents
            let lineToAdd = "auth       \(file == .sudo ? "sufficient" : "required  ")     \(pamLibLocationInOpt!)"
            switch task {
            case .enable:
                if f.state == .disable {
                    var index = 0
                    for line in (file == .sudo ? sudoContents : screensaverContents).contents.split(separator: "\n") {
                        if !line.contains("pam_opendirectory.so") {
                            index += 1
                        } else {
                            break
                        }
                    }
                    var array: [String] {
                        get {
                            var indexSelf = 0
                            var retval: [String] = []
                            f.contents.split(separator: "\n").forEach { line in
                                if indexSelf == index {
                                    retval.append(lineToAdd)
                                    retval.append(line.description)
                                } else {
                                    retval.append(line.description)
                                }
                                indexSelf += 1
                            }
                            return retval
                        }
                    }
                    var textToWrite = ""
                    array.forEach { line in
                        textToWrite += line + "\n"
                    }
                    FileManager().createFile(atPath: "/tmp/\(file == .sudo ? "sudo" : "screensaver")", contents: textToWrite.data(using: .utf8))
                    _ = Shell.Parcer.sudo("/bin/cp", ["/tmp/\(file == .sudo ? "sudo" : "screensaver")", "/etc/pam.d/\(file == .sudo ? "sudo" : "screensaver")"], password: password) as String
                    do {
                        try FileManager().removeItem(atPath: "/tmp/\(file == .sudo ? "sudo" : "screensaver")")
                    } catch let error {
                        NSLog(error.localizedDescription)
                    }
                }
            case .disable:
                if (file == .sudo ? sudoContents : screensaverContents).state == .enable {
                    var temp = ""
                    (file == .sudo ? sudoContents : screensaverContents).contents.split(separator: "\n").forEach { line in
                        if !line.contains(pamLibLocationInOpt!) {
                            temp += line + "\n"
                        }
                    }
                    FileManager().createFile(atPath: "/tmp/\(file == .sudo ? "sudo" : "screensaver")", contents: temp.data(using: .utf8))
                    _ = Shell.Parcer.sudo("/bin/cp", ["/tmp/\(file == .sudo ? "sudo" : "screensaver")", "/etc/pam.d/\(file == .sudo ? "sudo" : "screensaver")"], password: password) as String
                    do {
                        try FileManager().removeItem(atPath: "/tmp/\(file == .sudo ? "sudo" : "screensaver")")
                    } catch let error {
                        NSLog(error.localizedDescription)
                    }
                }
            }
            print("\(file == .sudo ? "Sudo" : "Screensaver") auth \(task == .enable ? "enabled" : "disabled")")
        }
    func checkInput(_ input: String) -> Bool {
        return Int(input) != nil && inRange(Int(input)!, rang: (enabled == .both || enabled == .neither ? 1...3 : 1...4))
    }
}

enum task {
    case enable
    case disable
}

enum file {
    case sudo
    case screensaver
}

enum whatIsEnabled {
    case sudo
    case screensaver
    case both
    case neither
}

func main() -> Int32 {
    let data = SystemAuthData()
    if data.notInstalled() {
        print("""
!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!ATTENTION!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!

Required software is not installed!
Please insert Your key do the following in Terminal:
1. brew install pam-u2f
2. mkdir -p ~/.config/Yubico/
3. pamu2fcfg > ~/.config/Yubico/u2f_keys
MAKE SURE TO FOLLOW THESE INSTRUCTION CORRECTLY
OTHERWISE THIS PROGRAM WILL NOT WORK
""")
        exit(-1)
    } else {
        let e = data.enabled
        print("""
Select action:
1. Toggle U2F for sudo auth in Terminal (current status: \(data.sudoContents.state == .disable ? "disabled" : "enabled"))
2. Toggle U2F for screensaver auth on login (current status: \(data.screensaverContents.state == .disable ? "disabled" : "enabled"))
\(data.enabled == .both ? "3. Disable all" : data.enabled == .neither ? "3. Enable all" : """
3. Enable all
4. Disable all
""")
\(data.enabled == .both || data.enabled == .neither ? "4" : "5"). Cancel and quit
""")
        var password = ""
        let input = readLine()!
        if data.checkInput(input) {
            password = String(cString: getpass("Enter password: "))
            if !Shell.Parcer.correctPassword(password) {
                print("Wrong password")
                exit(-1)
            }
        }
        switch e {
        case .both:
            switch input {
            case "1":
                data.edit(data.sudoContents.state == .disable ? .enable : .disable, .sudo, password)
            case "2":
                data.edit(data.screensaverContents.state == .disable ? .enable : .disable, .screensaver, password)
            case "3":
                data.edit(.disable, .sudo, password)
                data.edit(.disable, .screensaver, password)
            case "4":
                print("See you!")
            default:
                print("Wrong input")
                return -1
            }
            return 0
        case .neither:
            switch input {
            case "1":
                data.edit(data.sudoContents.state == .disable ? .enable : .disable, .sudo, password)
            case "2":
                data.edit(data.screensaverContents.state == .disable ? .enable : .disable, .screensaver, password)
            case "3":
                data.edit(.enable, .sudo, password)
                data.edit(.enable, .screensaver, password)
            case "4":
                print("See you!")
            default:
                print("Wrong input")
                return -1
            }
            return 0
        default:
            switch input {
            case "1":
                data.edit(data.sudoContents.state == .disable ? .enable : .disable, .sudo, password)
            case "2":
                data.edit(data.screensaverContents.state == .disable ? .enable : .disable, .screensaver, password)
            case "3":
                data.edit(.enable, .sudo, password)
                data.edit(.enable, .screensaver, password)
            case "4":
                data.edit(.disable, .sudo, password)
                data.edit(.disable, .screensaver, password)
            case "5":
                print("See you!")
            default:
                print("Wrong input")
                return -1
            }
            return 0
        }
    }
}

exit(main())
