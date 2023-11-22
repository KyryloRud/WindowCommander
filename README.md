# WindowCommander

The WindowCommander module provides functionality to seamlessly interact with view models via
 [SwiftUI Commands](https://developer.apple.com/documentation/swiftui/menus-and-commands). 

> Note: please, see the documentation on the GitHub pages: [WindowCommander](https://kyrylorud.github.io/WindowCommander/documentation/windowcommander/)

It allows users to obtain a context from the current interacted window
(in UIKit, a.k.a. [Key UIWindow](https://developer.apple.com/documentation/uikit/uiwindow),
currently there is no feature with similar functionality in SwiftUI),
bind this context with a specific class instance (such as a view model) related to this window,
and process the triggered command in it.

The WindowCommander module provides a simple solution which gives an easy way to establish this binding in several ways:

- Subscription on changes of window status: when it becomes a key window or background window.
- Subscription on all command triggers: receive event whenever any command was triggered for the key window.
- Establish binding between a specific command trigger and a specific model method to process it for the key window.
