//
//  WindowCommanderKit.swift
//  TestUI
//
//  Created by Kyrylo Rud on 05.11.2023.
//

import SwiftUI

protocol WKCommandTagHandler: AnyObject {
   func onCommandTriggered(tag: String)
}

protocol WKKeyWindowHandler: AnyObject {
   func onKeyWindowChanged(isKeyWindow: Bool)
}

fileprivate class HandlerWeakRef {
   public weak var handler: AnyObject?
   public var expired: Bool {
      get {
         handler == nil
      }
   }
   
   init(_ value: AnyObject) {
      self.handler = value
   }
}

fileprivate protocol MethodBindingHandler {
   var isEmpty: Bool { get }
   func trigger(command tag: String, for handler: AnyObject)
}

class WindowCommander {
   static let shared = WindowCommander()
   
   private typealias TypeID = Int
   public typealias MethodHandlerCallbackType = () -> Void
   
   private struct HandlerInfo {
      let typeID: TypeID
      let ref: HandlerWeakRef
      var windowID: UUID?
   }
   
   private class CommandToMethodsBindingHandler<HandlerType>: MethodBindingHandler {
      typealias KeyPathType = KeyPath<HandlerType, MethodHandlerCallbackType>
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
   
   private var mHandlerInstancesMap: [UUID /* instance id */: HandlerInfo] = [:]
   private var mHandlerTypesMap: [TypeID /* type id */: (instances: Set<UUID>, handler: MethodBindingHandler)] = [:]
   private var mWindowHandlersMap: [UUID /* window id */: Set<UUID/* related handler instance id */>] = [:]
   private var mObserverHandle: NSObjectProtocol? = nil
   
   private init() {
#if os(macOS)
      mObserverHandle = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: nil) { notification in
         if let window = notification.object as? NSWindow {
            DispatchQueue.main.async {
               self.onKeyWindowChanged(window.id)
            }
         }
      }
#endif
   }
   
   deinit {
      NotificationCenter.default.removeObserver(mObserverHandle!)
   }
   
   public func onCommand<HandlerType: AnyObject>(_ tag: String, process methodKeyPath: @escaping (HandlerType) -> MethodHandlerCallbackType) {
      let typeID = ObjectIdentifier(HandlerType.self).hashValue
      
      if mHandlerTypesMap[typeID] == nil {
         mHandlerTypesMap[typeID] = (instances: [], handler: CommandToMethodsBindingHandler<HandlerType>())
      }
      
      if let methodHandler = mHandlerTypesMap[typeID]!.handler as? CommandToMethodsBindingHandler<HandlerType> {
         methodHandler.commandTagAndMethodMap[tag] = methodKeyPath
      }
   }
   
   public func add<HandlerType: AnyObject>(handler: HandlerType) -> UUID {
      let instanceID = UUID()
      let typeID = ObjectIdentifier(HandlerType.self).hashValue
      
      mHandlerInstancesMap[instanceID] = .init(typeID: typeID, ref: .init(handler), windowID: nil)
      
      if mHandlerTypesMap.keys.firstIndex(where: { $0 == typeID }) == nil {
         let methodsHandler = CommandToMethodsBindingHandler<HandlerType>()
         mHandlerTypesMap[typeID] = (instances: [instanceID], handler: methodsHandler)
      } else {
         mHandlerTypesMap[typeID]?.instances.insert(instanceID)
      }
      
      return instanceID
   }
   
   public func remove(with instanceID: UUID) {
      if let instance = mHandlerInstancesMap[instanceID] {
         mHandlerTypesMap[instance.typeID]!.instances.remove(instanceID)
         
         if mHandlerTypesMap[instance.typeID]!.instances.isEmpty && mHandlerTypesMap[instance.typeID]!.handler.isEmpty {
            mHandlerTypesMap.removeValue(forKey: instance.typeID)
         }
         
         if let windowID = instance.windowID {
            mWindowHandlersMap[windowID]!.remove(instanceID)
            
            if mWindowHandlersMap[windowID]!.isEmpty {
               mWindowHandlersMap.removeValue(forKey: windowID)
            }
         }
         
         mHandlerInstancesMap.removeValue(forKey: instanceID)
      }
   }
   
   public func setCommand(handler instanceID: UUID, for windowID: UUID) {
      guard mHandlerInstancesMap[instanceID] != nil else { return }
      
      if mWindowHandlersMap[windowID] == nil {
         mWindowHandlersMap[windowID] = []
      }
      
      if let oldWindowID = mHandlerInstancesMap[instanceID]!.windowID {
         mWindowHandlersMap[oldWindowID]?.remove(instanceID)
      }
      
      mWindowHandlersMap[windowID]?.insert(instanceID)
      mHandlerInstancesMap[instanceID]!.windowID = windowID
   }
   
   public func command(_ tag: String) {
      var expiredHandlers: [UUID] = []
      
#if os(macOS)
      if let keyWindowID = NSApp.keyWindow?.id {
         if let handlersIDs = mWindowHandlersMap[keyWindowID] {
            for handlerID in handlersIDs {
               let handlerRef = mHandlerInstancesMap[handlerID]?.ref
               guard handlerRef != nil else { continue }
               
               if handlerRef!.expired {
                  expiredHandlers.append(handlerID)
               } else {
                  let instance = handlerRef!.handler
                  
                  if let commandTagHandler = instance as? WKCommandTagHandler {
                     commandTagHandler.onCommandTriggered(tag: tag)
                  }
                  
                  if let methodHandler = mHandlerTypesMap[mHandlerInstancesMap[handlerID]!.typeID]?.handler {
                     methodHandler.trigger(command: tag, for: instance!)
                  }
               }
            }
         }
      }
#endif
      
      expiredHandlers.forEach({ remove(with: $0) })
   }
   
   private func onKeyWindowChanged(_ keyWindowID: UUID) {
      var expiredHandlers: [UUID] = []
      
      for (windowID, handlerIDs) in mWindowHandlersMap {
         let isWindowActive = windowID == keyWindowID
         
         for handlerID in handlerIDs {
            let handlerRef = mHandlerInstancesMap[handlerID]?.ref
            guard handlerRef != nil else { continue }
            
            if handlerRef!.expired {
               expiredHandlers.append(handlerID)
            } else {
               if let keyWindowHandler = handlerRef!.handler as? WKKeyWindowHandler {
                  keyWindowHandler.onKeyWindowChanged(isKeyWindow: isWindowActive)
               }
            }
         }
      }
      
      expiredHandlers.forEach({ remove(with: $0) })
   }
}
