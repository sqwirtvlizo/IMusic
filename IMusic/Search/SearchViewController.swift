//
//  SearchViewController.swift
//  IMusic
//
//  Created by Алексей Пархоменко on 12/08/2019.
//  Copyright (c) 2019 Алексей Пархоменко. All rights reserved.
//

import UIKit

protocol SearchDisplayLogic: AnyObject {
    func displayData(viewModel: Search.Model.ViewModel.ViewModelData)
}

class SearchViewController: UIViewController, SearchDisplayLogic {

  var interactor: SearchBusinessLogic?
  var router: (NSObjectProtocol & SearchRoutingLogic)?
    weak var tabBarDelegate: MainTabBarControllerDelegate?
    
    @IBOutlet weak var table: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    private var searchViewModel = SearchViewModel.init(cells: [])
    private var timer: Timer?
    
    private lazy var footerView = FooterView()
      
  // MARK: Setup
  
  private func setup() {
    let viewController        = self
    let interactor            = SearchInteractor()
    let presenter             = SearchPresenter()
    let router                = SearchRouter()
    viewController.interactor = interactor
    viewController.router     = router
    interactor.presenter      = presenter
    presenter.viewController  = viewController
    router.viewController     = viewController
  }
  
  // MARK: Routing
  

  
  // MARK: View lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
    
    setupTableView()
    setupSearchBar()
  }

    override func viewWillAppear(_ animated: Bool) {
        let keyWindow = UIApplication.shared.connectedScenes.filter( {
            $0.activationState == .foregroundActive
        }).map( {
            $0 as? UIWindowScene
        }).compactMap({$0}).first?.windows.filter({
            $0.isKeyWindow
        }).first
        let tabBarVC = keyWindow?.rootViewController as? MainTabBarController
        tabBarVC?.trackDetailView.delegate = self
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
    }
    
    private func setupTableView() {
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        
        let nib = UINib(nibName: "TrackCell", bundle: nil)
        table.register(nib, forCellReuseIdentifier: TrackCell.reuseId)
        table.tableFooterView = footerView
    }
  
  func displayData(viewModel: Search.Model.ViewModel.ViewModelData) {

    switch viewModel {
    case .displayTracks(let searchViewModel):
        self.searchViewModel = searchViewModel
        table.reloadData()
        footerView.hideLoader()
    case .displayFooterView:
        footerView.showLoader()
    }
  }
  
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchViewModel.cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: TrackCell.reuseId, for: indexPath) as! TrackCell
        
        let cellViewModel = searchViewModel.cells[indexPath.row]
        cell.set(viewModel: cellViewModel)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellViewModel = searchViewModel.cells[indexPath.row]
//        let window = UIApplication.shared.keyWindow
//        let trackDetailsView: TrackDetailView = TrackDetailView.loadFromNib()
//       // let trackDetailsView = Bundle.main.loadNibNamed("TrackDetailView", owner: self)?.first as! TrackDetailView
//        trackDetailsView.delegate = self
//        window?.addSubview(trackDetailsView)
//        trackDetailsView.set(viewModel: cellViewModel)
        tabBarDelegate?.maximizeTrackDetailController(viewModel: cellViewModel)
        
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "Please enter search term above..."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return searchViewModel.cells.count > 0 ? 0 : 250
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            self.interactor?.makeRequest(request: Search.Model.Request.RequestType.getTracks(searchText: searchText))
        })
        
    }
}

extension SearchViewController: TrackMovingDelegate {
    
    private func getTrack(isForwardTrack: Bool) -> SearchViewModel.Cell? {
        guard let indexPath = table.indexPathForSelectedRow else { return nil }
        table.deselectRow(at: indexPath, animated: false)
        var nextIndex: IndexPath!
        if isForwardTrack {
            nextIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            if nextIndex.row == searchViewModel.cells.count {
                nextIndex.row = 0
            }
        } else {
            nextIndex = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            if nextIndex.row == -1 {
                nextIndex.row = searchViewModel.cells.count - 1
            }
        }
        table.selectRow(at: nextIndex, animated: false, scrollPosition: .none)
        let cellViewModel = searchViewModel.cells[nextIndex.row]
        return cellViewModel
    }
    
    func movePrevious() -> SearchViewModel.Cell? {
        getTrack(isForwardTrack: false)
    }
    
    func moveNext() -> SearchViewModel.Cell? {
        getTrack(isForwardTrack: true)
    }
}
