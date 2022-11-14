//
//  UserDefaults.swift
//  IMusic
//
//  Created by Евгений Кононенко on 14.11.2022.
//  Copyright © 2022 Алексей Пархоменко. All rights reserved.
//

import Foundation

extension UserDefaults {
    static var favouriteTrackKey = "favouriteTrackKey"
    
    func savedTracks() -> [SearchViewModel.Cell] {
        let defaults = UserDefaults.standard
        
        guard let savedTracks = defaults.object(forKey: UserDefaults.favouriteTrackKey) as? Data else { return [] }
        guard let decodedTracks = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedTracks) as? [SearchViewModel.Cell] else { return [] }
        return decodedTracks
    }
}
