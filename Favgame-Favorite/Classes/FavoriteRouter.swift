//
//  FavoriteRouter.swift
//  Favgame
//
//  Created by deri indrawan on 01/01/23.
//

import Foundation
import Favgame_core

public class FavoriteRouter {
  let container: Container = {
    let container = Injection().container
    
    container.register(FavoriteViewController.self) { resolver in
      let controller = FavoriteViewController()
      controller.getFavoriteGameUseCase = resolver.resolve(GetFavoritesGameUseCase.self)
      return controller
    }
    return container
  }()
}
