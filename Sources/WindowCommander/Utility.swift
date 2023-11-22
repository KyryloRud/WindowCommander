//
//  Utility.swift
//
//
//  Created by Kyrylo Rud on 22.11.2023.
//

import Foundation

/// Type alias for type id
internal typealias TypeID = Int

/// Get unique ``TypeID`` of specified type.
/// - Parameter type: Any class type.
/// - Returns: Unique ``TypeID`` of specified type.
internal func typeID(of type: AnyObject.Type) -> TypeID {
   return ObjectIdentifier(type.self).hashValue
}
