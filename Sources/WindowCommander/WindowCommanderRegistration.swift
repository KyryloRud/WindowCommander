//
//  WindowCommanderRegistration.swift
//  TestUI
//
//  Created by Kyrylo Rud on 15.11.2023.
//

import Foundation

extension WindowCommander {
   fileprivate struct HandlerMethodInfo<HandlerType> {
      let tag: String
      let handlerMethod: (HandlerType) -> MethodHandlerCallbackType
   }
   
   struct HandlerMethodRegistration<HandlerType: AnyObject> {
      fileprivate var info: HandlerMethodInfo<HandlerType>? = nil
      
      func onCommand(_ tag: String, process methodKeyPath: @escaping (HandlerType) -> MethodHandlerCallbackType) -> HandlerMethodRegistration {
         return HandlerMethodRegistration(info: HandlerMethodInfo(tag: tag, handlerMethod: methodKeyPath))
      }
   }
   
   @resultBuilder
   struct HandlerMethodsRegistrationBuilder<HandlerType: AnyObject> {
      static func buildBlock(_ components: HandlerMethodRegistration<HandlerType>...) -> [HandlerMethodRegistration<HandlerType>] {
         return components
      }
   }
   
   func register<HandlerType: AnyObject>(_: HandlerType.Type, @HandlerMethodsRegistrationBuilder<HandlerType> _ registrations: (HandlerMethodRegistration<HandlerType>) -> [HandlerMethodRegistration<HandlerType>]) {
      for registration in registrations(HandlerMethodRegistration()) {
         if let info = registration.info {
            WindowCommander.shared.onCommand(info.tag, process: info.handlerMethod)
         }
      }
   }
}
