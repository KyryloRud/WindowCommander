//
//  ProxyUIKitView.swift
//  TestUI
//
//  Created by Kyrylo Rud on 15.11.2023.
//

import SwiftUI

#if !os(macOS)

internal struct ProxyUIKitView: View {
   @Binding var windowID: UUID?
   
   var body: some View {
      EmptyView()
   }
}

#else

internal struct ProxyUIKitView: NSViewRepresentable {
   @Binding var windowID: UUID?
   
   class Coordinator: NSObject {
      var windowID: UUID?
   }
   
   func makeNSView(context: Context) -> NSView {
      let nsView = NSView()
      
      DispatchQueue.main.async {
         if let window = nsView.window {
            context.coordinator.windowID = window.id
            self.windowID = window.id
         }
      }
      
      return nsView
   }
   
   func updateNSView(_ nsView: NSView, context: Context) {}
   
   func makeCoordinator() -> Coordinator {
      Coordinator()
   }
}

#endif
