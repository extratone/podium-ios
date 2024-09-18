//
//  Environment.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import ComposableArchitecture
import Supabase
import Foundation

@DependencyClient
struct Supabase {}

extension DependencyValues {
  var supabase: SupabaseClient {
    get { self[Supabase.self] }
    set { self[Supabase.self] = newValue }
  }
}

extension Supabase: DependencyKey {
  static let liveValue = SupabaseClient(
    supabaseURL: URL(string: try! "https://" + ENV.value(for: "SUPABASE_URL"))!,
    supabaseKey: try! ENV.value(for: "SUPABASE_KEY")
  )
}

// Environment variables

enum ENV {
  enum Error: Swift.Error {
    case missingKey, invalidValue
  }
  
  static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
    guard let object = Bundle.main.object(forInfoDictionaryKey:key) else {
      throw Error.missingKey
    }
    
    switch object {
    case let value as T:
      return value
    case let string as String:
      guard let value = T(string) else { fallthrough }
      return value
    default:
      throw Error.invalidValue
    }
  }
}
