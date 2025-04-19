import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(StaticURLMacros)
import StaticURLMacros
import Foundation 

let testMacros: [String: Macro.Type] = [
    "staticURL": StaticURLMacro.self,
]
#endif

final class StaticURLTests: XCTestCase {
    func testMacro() throws {
        #if canImport(StaticURLMacros)
        assertMacroExpansion(
            """
            #staticURL("https://swiftbysundell.com")
            """,
            expandedSource: """
            Foundation.URL(string: "https://swiftbysundell.com")!
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroThrows() throws {
#if canImport(StaticURLMacros)
        assertMacroExpansion(
            """
            let url = #staticURL("https://swiftbysundiell.com")
            """,
            expandedSource: "",
            diagnostics: [
                DiagnosticSpec(message: "Argument is not a valid URL", line: 1, column: 1)
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
