import ArgumentParser
import Foundation

enum OutputType: String, EnumerableFlag, ExpressibleByArgument {
    case list
    case json
    
    var fileExt: String {
        switch self {
        case .list:
            return "txt"
        case .json:
            return "json"
        }
    }
}

extension String {
    var scheme: String {
        guard let url = URL(string: self) else {
            return ""
        }
        return url.scheme ?? ""
    }
}

struct DeeplinkTool: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "deeplink-tool",
        abstract: "A command-line tool to process deeplinks",
        discussion: "This tool reads a file with deeplinks, replaces the scheme, and generates output based on the specified flag.",
        version: "1.0.0",
        shouldDisplay: true
    )
    
    @Argument(help: "Path to the file containing deeplinks")
    var filePath: String
    
    @Option(name: .shortAndLong, help: "The flag to specify output format (--list or --json)")
    var outputType: OutputType
    
    @Option(name: .shortAndLong, help: "The custom scheme to replace existing schemes")
    var customScheme: String
    
    @Flag(name: .shortAndLong, help: "Generate separate output files grouped by base paths")
    var grouped: Bool = false
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() throws {
        
        if verbose {
            print(filePath)
        }
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ValidationError("The specified file path is invalid or does not exist.")
        }
        
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let deeplinks = contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let customScheme = customScheme.trimmingCharacters(in: NSCharacterSet(charactersIn: "://") as CharacterSet)
        if grouped {
            print("Generating grouped files...")
            let output = generateGroupedOutput(deeplinks: deeplinks, flag: outputType, customScheme: customScheme)
            try writeGroupedOutputs(output)
        } else {
            let output = generateOutput(deeplinks: deeplinks, flag: outputType, customScheme: customScheme)
            try writeOutput(output)
        }
        
        print("✅ Output generated successfully.")
    }
    
    func generateOutput(deeplinks: [String], flag: OutputType, customScheme: String) -> String {
        var output = ""
        
        switch flag {
        case .list:
            output = deeplinks.map { deeplink in
                deeplink.replacingOccurrences(of: deeplink.scheme , with: customScheme)
            }.joined(separator: "\n")
            
        case .json:
            var deeplinkJSON: [[String: Any]] = []
            
            for deeplink in deeplinks {
                let modifiedDeeplink = deeplink.replacingOccurrences(of: deeplink.scheme , with: customScheme)
                
                guard let url = URL(string: modifiedDeeplink) else {
                    continue
                }
                

                let title = generateTitle(from: url)
                
                let deeplinkDictionary: [String: Any] = [
                    "title": title,
                    "url": modifiedDeeplink,
                    "identifier": UUID().uuidString
                ]
                
                deeplinkJSON.append(deeplinkDictionary)
            }
            
            let jsonDictionary: [String: Any] = [
                "deeplinks": deeplinkJSON
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                output = jsonString
            }
        }
        
        return output
    }
    
    func generateGroupedOutput(deeplinks: [String], flag: OutputType, customScheme: String) -> [String: String] {
        switch flag {
        case .list:
            let groupedDeeplinks = groupDeeplinksByBasePath(deeplinks: deeplinks)
            var groupedList: [String: String] = [:]
            groupedDeeplinks.forEach { basePath, deeplinks in
                let modifiedDeeplinks = deeplinks.map { deeplink in
                    deeplink.replacingOccurrences(of: deeplink.scheme , with: customScheme)
                }.joined(separator: "\n")
                
                let lineOutput = "Base Path: \(basePath)\n\(modifiedDeeplinks)\n"
                groupedList[basePath] = lineOutput
            }
            return groupedList
            
        case .json:
            let groupedDeeplinks = groupDeeplinksByBasePath(deeplinks: deeplinks)
            var groupedJSON: [String: String] = [:]
            
            for (basePath, deeplinks) in groupedDeeplinks {
                var deeplinkJSON: [[String: Any]] = []
                
                for deeplink in deeplinks {
                    let modifiedDeeplink = deeplink.replacingOccurrences(of: deeplink.scheme , with: customScheme)
                    
                    guard let url = URL(string: modifiedDeeplink) else {
                        continue
                    }
                                
                    let title = generateTitle(from: url)
                    
                    let deeplinkDictionary: [String: Any] = [
                        "title": title,
                        "url": modifiedDeeplink,
                        "identifier": UUID().uuidString
                    ]
                    
                    deeplinkJSON.append(deeplinkDictionary)
                }
                
                let jsonDictionary: [String: Any] = [
                    "title": basePath,
                    "deeplinks": deeplinkJSON
                ]
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    groupedJSON[basePath] = jsonString
                }
            }
            return groupedJSON
        }
        
    }
    
    func generateTitle(from url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems?.compactMap({ item in
            return item.name.trimmingCharacters(in: NSCharacterSet(charactersIn: "://") as CharacterSet)
        }) ?? []
        components?.queryItems = nil
        let cleanURL = components?.url
        let pathComps = (
            [cleanURL?.host]
                .compactMap {
                    $0?.trimmingCharacters(in: NSCharacterSet(charactersIn: "://") as CharacterSet)
                } + (
                    cleanURL?.pathComponents.map {
                        $0.trimmingCharacters(in: NSCharacterSet(charactersIn: "://") as CharacterSet)
                    } ?? []
                )
        )
        let titleComponents = pathComps
            .filter { !$0.isEmpty }
        
        return (titleComponents + queryItems).prefix(10).joined(separator: "-")
    }
    
    func groupDeeplinksByBasePath(deeplinks: [String]) -> [String: [String]] {
        var groupedDeeplinks: [String: [String]] = [:]
        
        for deeplink in deeplinks {
            guard let url = URL(string: deeplink) else {
                continue
            }
            
            let basePath = url.host ?? ""
            if groupedDeeplinks[basePath] == nil {
                groupedDeeplinks[basePath] = [deeplink]
            } else {
                groupedDeeplinks[basePath]?.append(deeplink)
            }
        }
        
        return groupedDeeplinks
    }

    func writeOutput(_ output: String) throws {
        print("Writing deeplink in file...")
        let fileURL = URL(fileURLWithPath: "Output.\(outputType.fileExt)")
        try output.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func writeGroupedOutputs(_ groupedOutputs: [String: String]) throws {
        print("Writing grouped deeplink in files...")
        for (basePath, deeplinks) in groupedOutputs {
            let fileName = "\(basePath.replacingOccurrences(of: "/", with: "-")).\(outputType.fileExt)"
            let fileURL = URL(fileURLWithPath: fileName)
            try deeplinks.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}

DeeplinkTool.main()

