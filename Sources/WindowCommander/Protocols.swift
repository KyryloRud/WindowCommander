//
//  Protocols.swift
//
//
//  Created by Kyrylo Rud on 22.11.2023.
//

import Foundation

/// The complete list of methods for tag command handler.
///
/// A class that confirms this protocol should be registered in the corresponding window context.
/// The ``KeyWindowContext`` could be used for these purposes.
/// Whenever any command is triggered by ``WindowCommander`` with a tag,
/// the `onCommandTriggered` method with this tag will be executed on registered handlers in this window context.
public protocol WKCommandTagHandler: AnyObject {
   /// Process the triggered command.
   /// - Parameter tag: Command-associated tag.
   func onCommandTriggered(tag: String)
}

/// The complete list of methods for key window handler.
///
/// A class that confirms this protocol should be registered in the corresponding window context.
/// The ``KeyWindowContext`` could be used for these purposes.
/// Whenever the corresponding window context changes status (becomes a key or background window),
/// the `onKeyWindowChanged` will be triggered on registered handlers in this window context.
public protocol WKKeyWindowHandler: AnyObject {
   /// Process event, with a changed window status from the associated context.
   /// - Parameter isKeyWindow: New window status.
   func onKeyWindowChanged(isKeyWindow: Bool)
}
