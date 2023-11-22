//
//  KeyWindowContextModel.swift
//  TestUI
//
//  Created by Kyrylo Rud on 15.11.2023.
//

import SwiftUI

internal class KeyWindowContextModel: ObservableObject {
   private var handlerID: UUID? = nil
   private var isSubscribed: Bool = false
   
   private class KeyWindowSelectionHandlerWrapper: WKKeyWindowHandler {
      @Binding var isWindowActive: Bool
      
      init(isWindowActive isWindowActiveBinding: Binding<Bool>){
         _isWindowActive = isWindowActiveBinding
      }
      
      func onKeyWindowChanged(isKeyWindow: Bool) {
         self.isWindowActive = isKeyWindow
      }
   }
   private var windowHandler: KeyWindowSelectionHandlerWrapper? = nil
   
   func setHandler(_ isWindowActiveBinding: Binding<Bool>) {
      windowHandler = KeyWindowSelectionHandlerWrapper(isWindowActive: isWindowActiveBinding)
      handlerID = WindowCommander.shared.add(handler: windowHandler!)
   }
   
   func setHandler<WindowTagHandlerType: WKCommandTagHandler>(_ windowTagHandler: WindowTagHandlerType) {
      handlerID = WindowCommander.shared.add(handler: windowTagHandler)
   }
   
   func register(windowID: UUID) {
      guard handlerID != nil else { return }
      
      WindowCommander.shared.setCommand(handler: handlerID!, for: windowID)
   }
}
