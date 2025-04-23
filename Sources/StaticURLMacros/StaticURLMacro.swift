
import SwiftSyntax
//import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
//import SwiftSyntaxMacroExpansion
import SwiftDiagnostics
import SwiftCompilerPlugin

import Foundation

/// Implementation of the `staticURL` macro, which takes a static string and returns a non optional URL.
/// For example
///
///     let url = #staticURL("https://swiftbysundell.com")
///
///  will expand to
///
///     let url = Foundation.URL("https://swiftbysundell.com")!
///     
public struct StaticURLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // One string literal argument is required by the compiler. 
        // The text of the first segment contains the URL string passed in.
        
        guard let argument = node.arguments.first?.expression,
              let literal = argument.as(StringLiteralExprSyntax.self)
        else {
            let d = Diagnostic( node: node, message: StaticURLMacroDiagnostic.notAStringLiteral )
            context.diagnose(d)
            return ""
        }
        
        // get the urlstring from the first string literal segment
        let urlString = switch literal.segments.first {
            case .stringSegment(let segment): segment.content.text
            default: fatalError()
        }

        /// **Verify that the passed string is indeed a well formed URL:**
        ///  - Treat invalid characters as an error
        ///  - Check the address begins with http or https
        ///  - Have a non nil hostname
        ///  
        
        let url: URL? = 
            if #available(macOS 14.0, *) {
                URL(string: urlString, encodingInvalidCharacters: false)
            } else { 
                URL(string: urlString) 
            }
        if url == nil {
            return context.report(StaticURLMacroDiagnostic.invalidURL, argument: argument )
        }
        
        if !(url?.scheme ?? "").contains("http") {
            return context.report(StaticURLMacroDiagnostic.invalidScheme, argument: argument )
        }
        
        if (url!.host == nil) {
            return context.report(StaticURLMacroDiagnostic.invalidHost, argument: argument )
        }
        
        // Generate the code required to construct a URL value
        // for the passed string at runtime:
        return "Foundation.URL(string: \(argument))!"
    }
    
}

extension MacroExpansionContext {
    public func report(_ m: DiagnosticMessage, argument: ExprSyntax) -> ExprSyntax {
        let d = Diagnostic(node: Syntax(argument), message: m)
        self.diagnose(d)
        return "\(raw: m.message)"
    } 
}
    


enum StaticURLMacroDiagnostic: String, DiagnosticMessage {
    case notAStringLiteral, invalidURL, invalidScheme, invalidHost
    public var severity: DiagnosticSeverity { 
        switch self {
//            case .invalidHost: .warning
            default : .error
        }
    }
    public var message: String { 
         switch self {
            case .notAStringLiteral : "Argument is not a string literal"
            case .invalidURL : "Argument is not a valid URL"
            case .invalidScheme : "Web URL's must start with 'http://' or 'https://"
            case .invalidHost : "Web URL's must contain a valid hostname"
        }
    }
    public var diagnosticID: MessageID { 
        MessageID(domain: "StaticURLMacros" , id: rawValue )
    }
}

@main struct StaticURLPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [StaticURLMacro.self]
}
