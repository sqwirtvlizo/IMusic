//
//  SMTime + Extension.swift
//  IMusic
//
//  Created by Евгений Кононенко on 10.11.2022.
//  Copyright © 2022 Алексей Пархоменко. All rights reserved.
//

import Foundation
import AVKit

extension CMTime {
    func toDisplayString() -> String {
        guard !CMTimeGetSeconds(self).isNaN else { return "" }
        let totalSec = Int(CMTimeGetSeconds(self))
        let seconds = totalSec % 60
        let minutes = totalSec / 60
        let timeFormattedStr = String(format: "%02d:%02d", minutes, seconds)
        return timeFormattedStr
    }
}
