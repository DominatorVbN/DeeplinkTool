// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

enum OutputType: String, EnumerableFlag, ExpressibleByArgument {
    case list
    case json
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
    
    func run() throws {
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ValidationError("The specified file path is invalid or does not exist.")
        }
        
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let deeplinks = contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var output: String
        if grouped {
            output = generateGroupedOutput(deeplinks: deeplinks, flag: outputType, customScheme: customScheme)
        } else {
            output = generateOutput(deeplinks: deeplinks, flag: outputType, customScheme: customScheme)
        }
        
        if grouped {
            let groupedOutput = parseGroupedOutput(output)
            try writeGroupedOutputs(groupedOutput)
        } else {
            try writeOutput(output)
        }
        
        print("Output generated successfully.")
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
                
                let basePath = url.deletingLastPathComponent().path
                let title = generateTitle(from: basePath)
                
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
    
    func generateGroupedOutput(deeplinks: [String], flag: OutputType, customScheme: String) -> String {
        var output = ""
        
        switch flag {
        case .list:
            let groupedDeeplinks = groupDeeplinksByBasePath(deeplinks: deeplinks)
            output = groupedDeeplinks.map { basePath, deeplinks in
                let modifiedDeeplinks = deeplinks.map { deeplink in
                    deeplink.replacingOccurrences(of: deeplink.scheme , with: customScheme)
                }.joined(separator: "\n")
                
                return "Base Path: \(basePath)\n\(modifiedDeeplinks)\n"
            }.joined(separator: "\n")
            
        case .json:
            let groupedDeeplinks = groupDeeplinksByBasePath(deeplinks: deeplinks)
            var groupedJSON: [[String: Any]] = []
            
            for (basePath, deeplinks) in groupedDeeplinks {
                var deeplinkJSON: [[String: Any]] = []
                
                for deeplink in deeplinks {
                    let modifiedDeeplink = deeplink.replacingOccurrences(of: deeplink.scheme , with: customScheme)
                    
                    guard let url = URL(string: modifiedDeeplink) else {
                        continue
                    }
                    
                    let title = generateTitle(from: url.absoluteString)
                    
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
                
                groupedJSON.append(jsonDictionary)
            }
            
            let jsonDictionary: [String: Any] = [
                "deeplinks": groupedJSON
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                output = jsonString
            }
        }
        
        return output
    }
    
    func generateTitle(from basePath: String) -> String {
        let titleComponents = basePath
            .components(separatedBy: "/")
            .filter { !$0.isEmpty }
        
        return titleComponents.joined(separator: " ")
    }
    
    func groupDeeplinksByBasePath(deeplinks: [String]) -> [String: [String]] {
        var groupedDeeplinks: [String: [String]] = [:]
        
        for deeplink in deeplinks {
            guard let url = URL(string: deeplink) else {
                continue
            }
            
            let basePath = url.deletingLastPathComponent().path
            if groupedDeeplinks[basePath] == nil {
                groupedDeeplinks[basePath] = [deeplink]
            } else {
                groupedDeeplinks[basePath]?.append(deeplink)
            }
        }
        
        return groupedDeeplinks
    }
    
    func parseGroupedOutput(_ output: String) -> [(String, String)] {
        let components = output.components(separatedBy: "\n\n")
        return components.map { component in
            let lines = component.components(separatedBy: .newlines)
            let basePathLine = lines.first ?? ""
            let basePath = String(basePathLine.dropFirst("Base Path: ".count))
            let deeplinks = lines.dropFirst().joined(separator: "\n")
            return (basePath, deeplinks)
        }
    }
    
    func writeOutput(_ output: String) throws {
        let fileURL = URL(fileURLWithPath: "Output.txt")
        try output.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func writeGroupedOutputs(_ groupedOutputs: [(String, String)]) throws {
        for (basePath, deeplinks) in groupedOutputs {
            let fileName = "\(basePath.replacingOccurrences(of: "/", with: "-")).txt"
            let fileURL = URL(fileURLWithPath: fileName)
            try deeplinks.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}

DeeplinkTool.main()

