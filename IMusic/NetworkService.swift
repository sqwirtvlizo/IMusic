

import Foundation
import UIKit
import Alamofire

class NetworkService {
    func fetchTracks(searchText: String, completion: @escaping(SearchResponse?) -> Void) {
        let url = "https://itunes.apple.com/search"
        let parametrs = ["term" : "\(searchText)", "limit" : "40", "media" : "music"]
        AF.request(url, method: .get, parameters: parametrs, encoding: URLEncoding.default, headers: nil).responseData { data in
            if let error = data.error {
                print(error)
                completion(nil)
                return
            }
            guard let data = data.data else { return }
            let decoder = JSONDecoder()
            do {
                let objects = try decoder.decode(SearchResponse.self, from: data)
                completion(objects)
            } catch {
                print(error)
                completion(nil)
            }
        }
    }
}
