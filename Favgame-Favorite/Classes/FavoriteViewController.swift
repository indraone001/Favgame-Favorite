//
//  FavoriteViewController.swift
//  Favgame
//
//  Created by deri indrawan on 29/12/22.
//

import UIKit
import SkeletonView
import Combine
import RealmSwift
import Favgame_Core
import Favgame_Detail

public class FavoriteViewController: UIViewController {
  
  // MARK: - Properties
  var getFavoriteGameUseCase: GetFavoritesGameUseCase?
  private var cancellables: Set<AnyCancellable> = []
  private var gameList: [Game]?
  
  private let favoriteTableView: UITableView = {
    let table = UITableView(frame: .zero, style: .plain)
    table.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    table.isSkeletonable = true
    table.showsVerticalScrollIndicator = false
    table.register(GameTableViewCell.self, forCellReuseIdentifier: GameTableViewCell().identifier)
    return table
  }()
  
  // MARK: - Life Cycle
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.tabBarController?.tabBar.isHidden = false
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    navigationItem.title = "Favorite"
    let textAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.white,
      NSAttributedString.Key.font: Constant.fontBold
    ]
    navigationController?.navigationBar.titleTextAttributes = textAttributes
    navigationController?.navigationBar.tintColor = UIColor(rgb: Constant.rhinoColor)
    setupUI()
    fetchFavoritesGame()
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name(Constant.favoritePressedNotif),
      object: nil, queue: nil
    ) { _ in
      self.fetchFavoritesGame()
    }
  }
  
  // MARK: - Helper
  private func setupUI() {
    view.addSubview(favoriteTableView)
    favoriteTableView.anchor(
      top: view.safeAreaLayoutGuide.topAnchor,
      leading: view.leadingAnchor,
      bottom: view.safeAreaLayoutGuide.bottomAnchor,
      trailing: view.trailingAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingRight: 8
    )
    favoriteTableView.dataSource = self
    favoriteTableView.delegate = self
  }
  
  private func fetchFavoritesGame() {
    favoriteTableView.showSkeleton(usingColor: .gray, transition: .crossDissolve(0.25))
    getFavoriteGameUseCase?.execute()
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure:
          let alert = UIAlertController(title: "Alert", message: String(describing: completion), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self.present(alert, animated: true)
        case .finished:
          self.favoriteTableView.hideSkeleton()
          self.favoriteTableView.reloadData()
        }
      }, receiveValue: { [weak self] gameList in
        self?.gameList = gameList
      })
      .store(in: &cancellables)
  }
}

extension FavoriteViewController: UITableViewDataSource, UITableViewDelegate {

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if ((gameList?.isEmpty) != false) {
      let message = "This page is empty.\nFind your favorite game."
      self.favoriteTableView.setEmptyMessage(message)
    } else {
      self.favoriteTableView.restore()
    }
    return gameList?.count ?? 0
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: GameTableViewCell().identifier, for: indexPath) as? GameTableViewCell else {
      return UITableViewCell()
    }
    cell.layer.cornerRadius = 8
    
    guard let result = gameList else {
      return UITableViewCell()
    }
    let game = result[indexPath.row]
    cell.configure(with: game)
    return cell
  }
  
  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 120
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let game = gameList else { return }
    let selectedGameId = game[indexPath.row].id
    
    let detailVC = DetailRouter().container.resolve(DetailViewController.self)
    guard let detailVC = detailVC else { return }
    detailVC.configure(withGameId: selectedGameId)
    
    let nav = UINavigationController(rootViewController: detailVC)
    nav.modalPresentationStyle = .fullScreen
    
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    nav.navigationBar.standardAppearance = appearance
    nav.navigationBar.scrollEdgeAppearance = nav.navigationBar.standardAppearance
    nav.navigationBar.tintColor = .white
    present(nav, animated: true)
  }
  
  public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let verticalPadding: CGFloat = 8
    
    let maskLayer = CALayer()
    maskLayer.cornerRadius = 8
    maskLayer.backgroundColor = UIColor.black.cgColor
    maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding/2)
    cell.layer.mask = maskLayer
  }
}
