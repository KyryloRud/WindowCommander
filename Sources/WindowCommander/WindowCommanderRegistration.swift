//
//  WindowCommanderRegistration.swift
//  TestUI
//
//  Created by Kyrylo Rud on 15.11.2023.
//

import Foundation

public extension WindowCommander {
   /// Association of command tag to handler method.
   fileprivate struct HandlerMethodInfo<HandlerType> {
      /// Command tag.
      let tag: String
      
      /// Handler method.
      let handlerMethod: (HandlerType) -> MethodHandlerCallbackType
   }
   
   /// Helper structure to associate helper methods with a specific command.
   struct HandlerMethodRegistration<HandlerType: AnyObject> {
      fileprivate var info: HandlerMethodInfo<HandlerType>? = nil
      
      /// Associate a command tag with a specific method for a `HandlerType`.
      ///
      /// This method is semi-internal, it could be useful in some cases.
      ///
      /// > Note: It is not recommended to use this method directly. The `register` method should be used instead.
      /// - Parameters:
      ///   - tag: Command tag.
      ///   - methodKeyPath: Handler method to process commands with the specified tag.
      /// - Returns: Instance of ``WindowCommander/HandlerMethodRegistration`` with command tag to handler method association.
      public func onCommand(_ tag: String, process methodKeyPath: @escaping (HandlerType) -> MethodHandlerCallbackType) -> HandlerMethodRegistration {
         return HandlerMethodRegistration(info: HandlerMethodInfo(tag: tag, handlerMethod: methodKeyPath))
      }
   }
   
   /// Builder for ``WindowCommander/HandlerMethodRegistration`` collection.
   @resultBuilder
   struct HandlerMethodsRegistrationBuilder<HandlerType: AnyObject> {
      public static func buildBlock(_ components: HandlerMethodRegistration<HandlerType>...) -> [HandlerMethodRegistration<HandlerType>] {
         return components
      }
   }

   /// Register method mappings for a handler type.
   ///
   /// Usage example:
   /// ```swift
   /// WindowCommander.shared.register(Model.self) { model in
   ///    model.onCommand("open-file", process: Model.openFile)
   ///    model.onCommand("close-file", process: Model.closeFile)
   /// }
   /// ```
   /// - Parameters:
   ///   - type: Handler object type.
   ///   - registrations: Built list of ``HandlerMethodRegistration``s.
   func register<HandlerType: AnyObject>(_ type: HandlerType.Type, @HandlerMethodsRegistrationBuilder<HandlerType> _ registrations: (HandlerMethodRegistration<HandlerType>) -> [HandlerMethodRegistration<HandlerType>]) {
      for registration in registrations(HandlerMethodRegistration()) {
         if let info = registration.info {
            WindowCommander.shared.onCommand(info.tag, process: info.handlerMethod)
         }
      }
   }
}
