//
//  KeyWindowContext.swift
//  TestUI
//
//  Created by Kyrylo Rud on 15.11.2023.
//

import SwiftUI

/// Helper view to register command handlers in the current window context.
public struct KeyWindowContext<Content>: View where Content: View {
   @State private var windowID: UUID? = nil
   @State private var model = KeyWindowContextModel()
   private let content: () -> Content
   
   init(isWindowActiveBinding: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
      self.content = content
      model.setHandler(isWindowActiveBinding)
   }
   
   init(for handler: AnyObject, @ViewBuilder content: @escaping () -> Content) {
      self.content = content
      if let handler = handler as? WKCommandTagHandler {
         model.setHandler(handler)
      }
   }
   
   public var body: some View {
      content()
         .background(
            ProxyUIKitView(windowID: $windowID)
               .onChange(of: windowID) {
                  if let windowID = windowID {
                     model.register(windowID: windowID)
                  }
               }
         )
   }
}
