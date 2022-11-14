//
//  UIViewController + Storyboard.swift
//  IMusic
//
//  Created by Евгений Кононенко on 09.11.2022.
//  Copyright © 2022 Алексей Пархоменко. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    class func loadFromStoryboard<T: UIViewController>() -> T {
        let name = String(describing: T.self)
        let storyboard = UIStoryboard(name: name, bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() as? T {
            return vc
        } else {
            fatalError("No initial vc in \(name)")
        }
    }
}
