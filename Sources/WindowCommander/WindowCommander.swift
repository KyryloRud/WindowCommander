//
//  WindowCommanderKit.swift
//  TestUI
//
//  Created by Kyrylo Rud on 05.11.2023.
//

import SwiftUI

/// Handler wrapper to allow handler deletion on a zero reference counter.
fileprivate class HandlerWeakRef {
   /// Handler reference.
   public weak var handler: AnyObject?
   
   /// Computed property to check if the handler reference has expired.
   public var expired: Bool {
      get {
         handler == nil
      }
   }
   
   init(_ value: AnyObject) {
      self.handler = value
   }
}

/// Handler instance information.
fileprivate struct HandlerInfo {
   /// TypeID of stored handler instance.
   let typeID: TypeID
   
   /// Weak reference (``HandlerWeakRef``) of stored handler.
   let ref: HandlerWeakRef
   
   /// Related window `UUID` to the handler instance.
   var windowID: UUID?
}

/// An object that coordinates all command triggers by tags and registered handler instances.
public class WindowCommander {
   /// The shared ``WindowCommander`` instance.
   public static let shared = WindowCommander()
   
   /// Stored handler instances and their `UUID`s.
   private var mHandlerInstancesMap: [UUID /* instance id */: HandlerInfo] = [:]
   
   /// Mapping of ``TypeID`` of stored handlers to related `UUID`s handlers and ``MethodBindingHandler``.
   private var mHandlerTypesMap: [TypeID /* type id */: (instances: Set<UUID>, handler: MethodBindingHandler)] = [:]
   
   /// Mapping of WindowID to related handler `UUID`s.
   private var mWindowHandlersMap: [UUID /* window id */: Set<UUID/* related handler instance id */>] = [:]
   
   /// Handle of subscription for `NSWindow.didBecomeKeyNotification` notification.
   private var mObserverHandle: NSObjectProtocol? = nil

   /// Create an instance of ``WindowCommander``.
   ///
   /// > Note: This constructor is available only as a part of singleton pattern.
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
      if let handle = mObserverHandle {
         NotificationCenter.default.removeObserver(handle)
      }
   }
   
   /// Associate a command tag with a specific method for a `HandlerType`.
   ///
   /// > Note: It is not recommended to use this method directly. The `register` method should be used instead.
   /// - Parameters:
   ///   - tag: Command tag.
   ///   - methodKeyPath: Handler method to process commands with the specified tag.
   internal func onCommand<HandlerType: AnyObject>(_ tag: String, process methodKeyPath: @escaping (HandlerType) -> MethodHandlerCallbackType) {
      let typeID = typeID(of: HandlerType.self)
      
      if mHandlerTypesMap[typeID] == nil {
         mHandlerTypesMap[typeID] = (instances: [], handler: MethodsBindingHandler<HandlerType>())
      }
      
      if let methodHandler = mHandlerTypesMap[typeID]!.handler as? MethodsBindingHandler<HandlerType> {
         methodHandler.commandTagAndMethodMap[tag] = methodKeyPath
      }
   }

   /// Add a handler instance to the ``WindowCommander`` registry.
   ///
   /// It is possible to add the same instance more than once to the registry.
   /// This will cause command processing for each call.
   ///
   /// > Note: It is not recommended to use this method directly. The ``KeyWindowContext`` will do this itself.
   /// - Parameter handler: A handler instance.
   /// - Returns: `UUID` of registred handler.
   internal func add<HandlerType: AnyObject>(handler: HandlerType) -> UUID {
      let instanceID = UUID()
      let typeID = typeID(of: HandlerType.self)
      
      mHandlerInstancesMap[instanceID] = .init(typeID: typeID, ref: .init(handler), windowID: nil)
      
      if mHandlerTypesMap.keys.firstIndex(where: { $0 == typeID }) == nil {
         let methodsHandler = MethodsBindingHandler<HandlerType>()
         mHandlerTypesMap[typeID] = (instances: [instanceID], handler: methodsHandler)
      } else {
         mHandlerTypesMap[typeID]?.instances.insert(instanceID)
      }
      
      return instanceID
   }
   
   /// Remove a handler instance from the ``WindowCommander`` registry.
   ///
   /// > Note: It is not recommended to use this method directly. The ``KeyWindowContext`` will do this itself.
   /// - Parameter instanceID: `UUID` of registred handler.
   internal func remove(with instanceID: UUID) {
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
   
   /// Associate a handler with a specific window context.
   ///
   /// > Note: It is not recommended to use this method directly. The ``KeyWindowContext`` will do this itself.
   /// - Parameters:
   ///   - instanceID: `UUID` of handler instance added to ``WindowCommander`` via `add` method.
   ///   - windowID: `UUID` of window instance of `NSWindow`.
   internal func setCommand(handler instanceID: UUID, for windowID: UUID) {
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
   
   /// Trigger command.
   /// - Parameter tag: Tag name of the triggered command.
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
   
   /// Process updates on key window events.
   /// - Parameter keyWindowID: `UUID` of the new key window.
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
