//
//  Coordinator.swift
//  TestsDemo
//
//  Created by Hithakshi on 21/01/25.
//

#if !os(macOS)
import Foundation
import UIKit

extension Array where Element == Coordinator {

    mutating func remove(_ coordinator: Coordinator) {
        removeAll(where: { $0 === coordinator })
    }
}


extension UINavigationController: Navigator {}

// MARK: - Base Coordinator Implementation
open class BaseCoordinator: NSObject, BaseCoordinating {
    private let navigationController: UINavigationController
    public  weak var parentCoordinator: BaseCoordinating?
    public var childCoordinators: [Coordinator] = []
    public let appDependencies: AppDependencies
    public var cleanUp: CleanUpOperation?
    public let presentationType: PresentationType

    private(set) var initialViewController: UIViewController?

    required public init(navigator: Navigator, appDependencies: AppDependencies, presentationType: PresentationType) {
        self.navigationController = navigator as! UINavigationController
        self.appDependencies = appDependencies
        self.presentationType = presentationType
        super.init()
        if navigationController.delegate == nil {
            navigationController.delegate = self
        }
    }

    open func start() {
        fatalError("Start method must be implemented by derived coordinator")
    }

    public func createChildCoordinator<T: BaseCoordinating>(coordinator: T.Type, presentationType: PresentationType) -> T {
        T.init(navigator: navigationController, appDependencies: appDependencies, presentationType: presentationType)
    }

    public func createChildCoordinator<T: BaseCoordinating>(factory: (Navigator) -> T) -> T {
        factory(navigationController)
    }

    public func createChildCoordinator<T: BaseCoordinating>(factory: (Navigator) -> T?) -> T? {
        factory(navigationController)
    }

    open func stop() {
        // Clean up any resources and notify parent
        removeChildren()
        cleanUp?(self)
        parentCoordinator?.removeChildCoordinator(self)
    }

    private func removeChildren() {
        childCoordinators.forEach { $0.stop() }
        childCoordinators.removeAll()
    }

    public func addChildCoordinator(_ coordinator: BaseCoordinating) {
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }

    public func removeChildCoordinator(_ coordinator: BaseCoordinating) {
        childCoordinators.remove(coordinator)
    }

    // MARK: - Navigation Helpers

    open func setInitial(viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        self.initialViewController = viewController
        switch presentationType {
        case .push:
            navigationController.pushViewController(viewController, animated: animated)
            if let completion = completion {
                completion()
            }

        case let .presentWith(presenter, style):
            navigationController.setViewControllers([viewController], animated: true)
            navigationController.modalPresentationStyle = style
            presenter.present(navigationController, animated: true)

        case .present(let style):
            viewController.modalPresentationStyle = style
            navigationController.present(viewController, animated: animated, completion: completion)

        case .embed(let parentViewController, let containerView):
            parentViewController.addChild(viewController)
            containerView.addSubview(viewController.view)
            viewController.view.frame = containerView.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            viewController.didMove(toParent: parentViewController)
            if let completion = completion {
                completion()
            }

        case .root(let window):
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            if let completion = completion {
                completion()
            }

        case .custom:
            fatalError("Support custom presentation type in your derived coordinator")
        }
    }

    public func push(viewController: UIViewController, animated: Bool) {
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func popToRoot(animated: Bool) {
        navigationController.popToRootViewController(animated: animated)
    }
}

extension BaseCoordinator: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Handle back navigation (swipe or button)
        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
              !navigationController.viewControllers.contains(fromViewController) else {
            return
        }
        if fromViewController == initialViewController {
            stop()
        }
    }

}
#endif
