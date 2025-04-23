// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces a URL from a static string that is checked at compile time.
///
///     let url = #staticURL("https://swiftbysundell.com")
///
/// produces a non optional URL

import Foundation


@freestanding(expression)
public macro staticURL(_ value: StaticString) -> URL = 
    #externalMacro( module: "StaticURLMacros", type: "StaticURLMacro" )



/// To add dynamic components, use overloads of the appending API as in the following example
///
///     actor NetworkingService {
///     private static let baseURL = #staticURL("https://api.myapp.com")
///...
///
///       func loadUser(withID id: User.ID) async throws -> User {
///         let url = Self.baseURL
///             .appending(components: "users", id)
///             .appending(queryItems: [
///             URLQueryItem(name: "refresh", value: "true")
///         ])
///    
///    ...
///       }
///     }
/// 
