//
//  KeyWindowContext.swift
//  TestUI
//
//  Created by Kyrylo Rud on 15.11.2023.
//

import SwiftUI

/// Helper view to register command handlers in the current window context.
///
/// This view helps to associate a class instance with the current window context.
/// It should wrap any context in any view that is created in some window.
///
/// ```swift
/// struct ContentView: View {
///    @State private var model: Model = Model()
///
///    var body: some View {
///       KeyWindowContext(for: model) {
///          Text("Content view")
///       }
///    }
/// }
/// ```
///
/// It is easy to register any handler type in ``KeyWindowContext``,
/// also has a convinient interface to subscribe for key window updates only.
///
/// ```swift
/// struct ContentView: View {
///    @State private var isKeyWindow: Bool = false
///
///    var body: some View {
///       KeyWindowContext(isKeyWindow: $isKeyWindow) {
///          Text("Content view")
///       }
///    }
/// }
/// ```
/// > Note: All views defined inside ``KeyWindowContext`` will be represented as is.
public struct KeyWindowContext<Content>: View where Content: View {
   /// Window ID of related context.
   @State private var windowID: UUID? = nil
   
   /// Internal context model to wrap interactions with ``WindowCommander``.
   @State private var model = KeyWindowContextModel()
   
   /// User-defined content to display without changes (wrapped by ``KeyWindowContext``).
   private let content: () -> Content
   
   /// Creates ``KeyWindowContext`` and binds a `Bool` state variable to key window updates.
   /// - Parameters:
   ///   - isKeyWindow: Status of the window in its context.
   ///   - content: User content to display without changes.
   public init(isKeyWindow: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
      self.content = content
      model.setHandler(isKeyWindow)
   }

   /// Creates ``KeyWindowContext`` and binds a handler instance to triggered command updates.
   ///
   /// If the handler confirms  ``WKCommandTagHandler`` or/and ``WKKeyWindowHandler`` appropriate methods will be triggered.
   /// Otherwise, it will be processed only by registered methods via ``WindowCommander``.
   ///
   /// > Note: All handler functions are independent, and all methods will be triggered independently.
   /// - Parameters:
   ///   - handler: A handler instance to process triggered commands.
   ///   - content: User content to display without changes.
   public init(for handler: AnyObject, @ViewBuilder content: @escaping () -> Content) {
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
