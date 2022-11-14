

import UIKit
import Alamofire

class SearchMusicViewController: UITableViewController {
    
    private var timer = Timer()
    private let searchController = UISearchController(searchResultsController: nil)
    private var arrayOfTracks = [Track]()
    private var networkService = NetworkService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrayOfTracks.count
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(arrayOfTracks[indexPath.row].trackName)\n\(arrayOfTracks[indexPath.row].artistName)"
        cell.textLabel?.numberOfLines = 2
        cell.imageView?.image = UIImage(named: "search")
        return cell
    }
    
}

extension SearchMusicViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.networkService.fetchTracks(searchText: searchText) { [weak self] object in
                self?.arrayOfTracks = object?.results ?? []
                self?.tableView.reloadData()
            }
        })
    }
}
