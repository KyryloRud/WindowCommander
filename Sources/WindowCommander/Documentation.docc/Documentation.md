# ``WindowCommander``

Create contextual connection between SwiftUI Command execution and current active window.

@Metadata {
   @Available(iOS, introduced: "14.0")
   @Available(macOS, introduced: "14.0")
   @Available(macCatalyst, introduced: "14.0")
   @Available(visionOS, introduced: "1.0 Beta")
}

## Overview

The WindowCommander module provides functionality to seamlessly interact with view models via
 [SwiftUI Commands](https://developer.apple.com/documentation/swiftui/menus-and-commands). 

It allows users to obtain a context from the current interacted window
(in UIKit, a.k.a. [Key UIWindow](https://developer.apple.com/documentation/uikit/uiwindow),
currently there is no feature with similar functionality in SwiftUI),
bind this context with a specific class instance (such as a view model) related to this window,
and process the triggered command in it.

The WindowCommander module provides a simple solution which gives an easy way to establish this binding in several ways:

- Subscription on changes of window status: when it becomes a key window or background window.
- Subscription on all command triggers: receive event whenever any command was triggered for the key window.
- Establish binding between a specific command trigger and a specific model method to process it for the key window.

@Small {
    _Licensed under Apache License v2.0._
}
