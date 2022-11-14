//
//  Nib.swift
//  IMusic
//
//  Created by Евгений Кононенко on 10.11.2022.
//  Copyright © 2022 Алексей Пархоменко. All rights reserved.
//

import UIKit

extension UIView {
    class func loadFromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
