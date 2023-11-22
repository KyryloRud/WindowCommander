//
//  NSWindow.swift
//  TestUI
//
//  Created by Kyrylo Rud on 05.11.2023.
//

import SwiftUI

#if os(macOS)

fileprivate var uniqueIDD: Int = 0

extension NSWindow: Identifiable {
   fileprivate struct AssociatedKeys {
      static var uniqueID: Int = 0
   }
   
   public var id: UUID {
      get {
         if let id = objc_getAssociatedObject(self, &uniqueIDD) as? UUID {
            return id
         } else {
            let uniqueID = UUID()
            objc_setAssociatedObject(self, &uniqueIDD, uniqueID, .OBJC_ASSOCIATION_RETAIN)
            return uniqueID
         }
      }
   }
}

#endif
