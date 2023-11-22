//
//  MethodsBindingHandler.swift
//  
//
//  Created by Kyrylo Rud on 22.11.2023.
//

import Foundation

/// Type alias for method handler callback.
///
/// Defines a method signature that could process a command execution.
/// Only methods with this signature could be registered in ``WindowCommander``.
public typealias MethodHandlerCallbackType = () -> Void

/// The complete list of properties and methods for internal method-binding handler.
internal protocol MethodBindingHandler {
   /// If the handler contain any bound methods.
   var isEmpty: Bool { get }
   
   /// Call the instance method associated with a specific handler on a specified instance.
   /// - Parameters:
   ///   - tag: Command-associated tag.
   ///   - handler: Instance of handler that should be triggered via the corresponding method on a command-associated tag signal.
   func trigger(command tag: String, for handler: AnyObject)
}

/// Container to map the command tag to the handler method.
internal class MethodsBindingHandler<HandlerType>: MethodBindingHandler {
   /// Type alias for the method signature.
   typealias KeyPathType = KeyPath<HandlerType, MethodHandlerCallbackType>

   /// Mapped command tag to handler method.
   var commandTagAndMethodMap: [String: (HandlerType) -> MethodHandlerCallbackType]
   
   var isEmpty: Bool {
      get {
         commandTagAndMethodMap.isEmpty
      }
   }
   
   init() {
      commandTagAndMethodMap = [:]
   }
   
   func trigger(command tag: String, for handler: AnyObject) {
      if let method = commandTagAndMethodMap[tag] {
         if let instance = handler as? HandlerType {
            method(instance)()
         }
      }
   }
}
