import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
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
        // Verify that a string literal was passed, and extract
        // the first segment. We can be sure that only one
        // segment exists, since we're only accepting static
        // strings (which cannot have any dynamic components):
        guard let argument = node.arguments.first?.expression,
              let literal = argument.as(StringLiteralExprSyntax.self),
              case .stringSegment(let segment) = literal.segments.first
        else {
            throw StaticURLMacroError.notAStringLiteral
        }
        
        // Verify that the passed string is indeed a valid URL:
        guard URL(string: segment.content.text) != nil else {
            throw StaticURLMacroError.invalidURL
        }
        
        // Generate the code required to construct a URL value
        // for the passed string at runtime:
        return "Foundation.URL(string: \(argument))!"
    }
}

public enum StaticURLMacroError: String, Error, CustomStringConvertible {
    case notAStringLiteral = "Argument is not a string literal"
    case invalidURL = "Argument is not a valid URL"
    
    public var description: String { rawValue }
}

@main struct StaticURLPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [StaticURLMacro.self]
}
