//
//  Shell.swift
//  TORVpn
//
//  Created by Олег Сазонов on 05.06.2022.
//

import Foundation

public class Shell {
    public class Runner {
        //MARK: - INIT and DEINIT
        public init(app: String = "/opt/homebrew/bin/tor", args: [String] = []) {
            func getAppPath(_ app: String) -> URL {
                let p = Process()
                let pi = Pipe()
                p.standardOutput = pi
                p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                p.arguments = [app]
                var retval = ""
                do {
                    try p.run()
                    retval = String(data: pi.fileHandleForReading.availableData, encoding: .utf8)!
                } catch let error {
                    NSLog(error.localizedDescription)
                    p.interrupt()
                }
                return URL(fileURLWithPath: String(retval.dropLast()))
            }
            appPath = getAppPath(app)
            process = Process()
            pipe = Pipe()
            process.executableURL = appPath
            process.arguments = args
            process.standardOutput = pipe
        }
        public init(appURL: URL, args: [String]) {
            appPath = appURL
            process = Process()
            pipe = Pipe()
            process.executableURL = appURL
            process.arguments = args
            process.standardOutput = pipe
        }
        //MARK: - Vars
        private var appPath: URL = .init(fileURLWithPath: "")
        public var process: Process = Process()
        public var pipe: Pipe = Pipe()
        
        //MARK: - Funcs
        public func getAppPath(_ app: String) -> URL {
            let p = Process()
            let pi = Pipe()
            p.standardOutput = pi
            p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            p.arguments = [app]
            var retval = ""
            do {
                try p.run()
                retval = String(data: pi.fileHandleForReading.availableData, encoding: .utf8)!
            } catch let error {
                NSLog(error.localizedDescription)
                p.interrupt()
            }
            return URL(fileURLWithPath: String(retval.dropLast()))
        }
        
        public func stopTask() {
            do {
                process.terminate()
                try pipe.fileHandleForReading.close()
            } catch let error {
                NSLog(String(error.localizedDescription))
            }
        }
        
        public func returnAllOutput() -> String {
            var string = Data()
            do{
                try string = pipe.fileHandleForReading.readToEnd() ?? pipe.fileHandleForReading.availableData
            } catch let error {
                NSLog(error.localizedDescription)
            }
            let retval = String(data: string, encoding: .utf8)!
            return retval
        }
    }
    
    //MARK: - Shell Script Parcer
    //MARK: Public
    /// Parces and executes shell I/O
    public class Parcer {
        //MARK: - Functions
        //MARK: Public
        /// Can execute pipe
        /// - Parameters:
        ///   - firstExe: unix-path to first executable
        ///   - secondExe: unix-path to second executable
        ///   - firstArgs: first executable args
        ///   - secondArgs: second executable args
        /// - Returns: command output
        public class func twoExecutables(firstExe: String, secondExe: String, firstArgs: [String], secondArgs: [String]) -> String {
            let taskOne = Process()
            taskOne.executableURL = URL(fileURLWithPath: firstExe)
            taskOne.arguments = firstArgs
            
            let taskTwo = Process()
            taskTwo.executableURL = URL(fileURLWithPath: secondExe)
            taskTwo.arguments = secondArgs
            
            let pipeBetween:Pipe = Pipe()
            taskOne.standardOutput = pipeBetween
            taskTwo.standardInput = pipeBetween
            
            let pipeToMe = Pipe()
            taskTwo.standardOutput = pipeToMe
            taskTwo.standardError = pipeToMe
            
            do {
                try taskOne.run()
                try taskTwo.run()
            } catch let error {
                NSLog(error.localizedDescription)
            }
            
            let data = pipeToMe.fileHandleForReading.readDataToEndOfFile()
            let output : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
            return output
        }
        /// Can execute pipe
        /// - Parameters:
        ///   - firstExe: unix-path to first executable
        ///   - secondExe: unix-path to second executable
        ///   - firstArgs: first executable args
        ///   - secondArgs: second executable args
        public class func twoExecutables(firstExe: String, secondExe: String, firstArgs: [String], secondArgs: [String]) -> Void {
            let taskOne = Process()
            taskOne.executableURL = URL(fileURLWithPath: firstExe)
            taskOne.arguments = firstArgs
            
            let taskTwo = Process()
            taskTwo.executableURL = URL(fileURLWithPath: secondExe)
            taskTwo.arguments = secondArgs
            
            let pipeBetween:Pipe = Pipe()
            taskOne.standardOutput = pipeBetween
            taskTwo.standardInput = pipeBetween
            
            let pipeToMe = Pipe()
            taskTwo.standardOutput = pipeToMe
            taskTwo.standardError = pipeToMe
            
            do {
                try taskOne.run()
                try taskTwo.run()
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }

        /// Executes one shell command
        /// - Parameters:
        ///   - exe: path to executable
        ///   - args: args of executable
        /// - Returns: console output
        public class func oneExecutable(exe: String, args: [String]) -> String {
            let process = Process()
            var output = String()
            process.executableURL = URL(fileURLWithPath: exe)
            process.arguments = args
            let pipe = Pipe()
            process.standardOutput = pipe
            do {
                let data = try pipe.fileHandleForReading.readToEnd()
                output = (NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "") as String
                try process.run()
            } catch let error {
                process.interrupt()
                NSLog(error.localizedDescription)
            }
            return output
        }
        /// Executes one shell command
        /// - Parameters:
        ///   - exe: path to executable
        ///   - args: args of executable
        public class func oneExecutable(exe: String, args: [String]) -> Void {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: exe)
            process.arguments = args
            do {
                try process.run()
            } catch let error {
                process.interrupt()
                NSLog(error.localizedDescription)
            }
        }
        
        /// Executes one shell command
        /// - Parameters:
        ///   - exe: path to executable
        ///   - args: args of executable
        /// - Returns: Pipe to process
        public class func oneExecutable(exe: String, args: [String]) -> Pipe {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: exe)
            process.arguments = args
            do {
                process.standardOutput = pipe
                try process.run()
            } catch let error {
                process.interrupt()
                NSLog(error.localizedDescription)
            }
            return pipe
        }

        /// Runs SUDO in swift
        /// - Parameters:
        ///   - exe: path to executable to runn with sudo
        ///   - args: args of executable
        ///   - password: admin password
        /// - Returns: command output
        public class func sudo(_ exe: String, _ args: [String], password: String) -> String {
            let taskOne = Process()
            taskOne.executableURL = URL(fileURLWithPath: "/bin/echo")
            taskOne.arguments = [password]
            
            let taskTwo = Process()
            taskTwo.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            let args4Sudo = ["-S", exe] + args
            taskTwo.arguments = args4Sudo
            
            let pipeBetween:Pipe = Pipe()
            taskOne.standardOutput = pipeBetween
            taskTwo.standardInput = pipeBetween
            
            let pipeToMe = Pipe()
            taskTwo.standardOutput = pipeToMe
            taskTwo.standardError = pipeToMe
            
            do {
                try taskOne.run()
                try taskTwo.run()
            } catch let error {
                NSLog(error.localizedDescription)
            }
            
            let data = pipeToMe.fileHandleForReading.readDataToEndOfFile()
            let output : String = String(data: data, encoding: .utf8)!
            return output
        }
        
        /// Runs SUDO in swift
        /// - Parameters:
        ///   - exe: path to executable to runn with sudo
        ///   - args: args of executable
        ///   - password: admin password
        public class func sudo(_ exe: String, _ args: [String], password: String) -> Void {
            let taskOne = Process()
            taskOne.executableURL = URL(fileURLWithPath: "/bin/echo")
            taskOne.arguments = [password]
            
            let taskTwo = Process()
            taskTwo.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            let args4Sudo = ["-S", exe] + args
            taskTwo.arguments = args4Sudo
            
            let pipeBetween:Pipe = Pipe()
            taskOne.standardOutput = pipeBetween
            taskTwo.standardInput = pipeBetween
            
            let pipeToMe = Pipe()
            taskTwo.standardOutput = pipeToMe
            taskTwo.standardError = pipeToMe
            
            do {
                try taskOne.run()
                try taskTwo.run()
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }

        /// Checks if password provided is correct (use as variable value to eras in case of wrong input)
        /// - Parameter password: admin password
        /// - Returns: true if password is correct, false, if not
        public class func correctPassword(_ password: String) -> Bool {
            let pwd: String = sudo("/bin/cat", ["/etc/sudoers"], password: password)
            switch pwd {
            case
                """
                Password:Sorry, try again.
                Password:
                sudo: no password was provided
                sudo: 1 incorrect password attempt
                
                """
                :
                return false
            default : return true
            }
        }
        
        public class func directLaunchWithoutOutput(ApplicationName appName: String, ApplicationArguments arguments: String?) throws {
            let process = Process()
            process.executableURL = URL(filePath: "/bin/bash")
            process.arguments = ["-c", arguments == nil ? appName : appName + " " + arguments!]
            do {
                try process.run()
            } catch let error {
                NSLog(error.localizedDescription)
                throw error
            }
        }
        
        //MARK: - Initializer
        public init() {}
    }
    //MARK: - "/etc/pam.d/sudo" file processing
    //MARK: Public
    /// This class checks for existance of custom entry in '/etc/pam.d/sudo' which invokes TouchID prior to password.
    public class macOS_Auth_Subsystem {
        //MARK: - Constant
        //MARK: Private
        private let stringToAdd = "auth       sufficient     pam_tid.so"
        
        //MARK: - Functions
        //MARK: Private
        /// Gets contents of "/etc/pam.d/sudo"
        /// - Returns: String representation of file contents
        private var tid: String {
            get {
                do {
                    return try String(contentsOfFile: "/etc/pam.d/sudo", encoding: .utf8)
                } catch _ {
                    return ""
                }
            }
        }
        
        /// Writes data to file
        /// - Parameters:
        ///   - input: used mainly for adding 'auth       sufficient     pam_tid.so' to sudo file
        ///   - password: sudo password
        private func writeToFile(_ input: String, _ password: String) {
            let fm = FileManager()
            fm.createFile(atPath: "/tmp/sudo", contents: input.data(using: .utf8), attributes: [:])
            _ = Shell.Parcer.sudo("/bin/cp", ["/tmp/sudo", "/etc/pam.d/sudo"], password: password) as String
            do {
                try fm.removeItem(atPath: "/tmp/sudo")
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }
        
        /// Generates enabling TouchID string to add into pam.d/sudo file
        /// - Returns: Complete contents of existing file with addition of enabling string
        private func addToPam() -> String {
            var retval = ""
            switch analyzePam_d() {
            case false:
                let firstLine = "# sudo: auth account password session"
                let secondLine = stringToAdd
                let theRest = tid.replacingOccurrences(of: firstLine, with: "")
                retval = firstLine + "\n" + secondLine + theRest
            case true: break
            }
            return retval
        }
        
        /// Generates disabling TouchID string to remove from pam.d/sudo file
        /// - Returns: Complete contents of existing file without addition of enabling string
        private func removeFromPam() -> String {
            var retvalComplete = ""
            switch analyzePam_d(){
            case true: retvalComplete = tid.replacingOccurrences(of: stringToAdd, with: "")
            case false: break
            }
            let retval = retvalComplete.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).filter{!$0.isEmpty}.joined(separator: "\n")
            return retval
        }

        //MARK: - Functions
        //MARK: Public
        
        /// Switches state of TouchID: enables it prior to password input and vice versa
        /// - Parameter password: sudo (superuser) password
        public func switchState(_ password: String) -> Void {
            switch analyzePam_d() {
            case true: writeToFile(removeFromPam(),password)
            case false: writeToFile(addToPam(),password)
            }
        }
        
        
        /// Analyzes "/etc/pam.d/sudo" file and returns true or false
        /// - Returns: "true" if TouchID is enables and "false" if not
        public func analyzePam_d() -> Bool {
            let pam_d = tid
            switch pam_d.contains(stringToAdd) {
            case true : return true
            case false : return false
            }
        }
        
        /// Returns localized description (string in Localizations file) whether TouchID is enables
        /// - Returns: Localized string
        public func localizedDescriptionOfPam() -> String {
            let status = analyzePam_d()
            switch status {
            case true: return NSLocalizedString("enabled.string", comment: "")
            case false: return NSLocalizedString("disabled.string", comment: "")
            }
        }
        
        //MARK: - Initializer
        public init() {}
    }
}
