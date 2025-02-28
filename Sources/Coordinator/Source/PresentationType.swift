//
//  PresentationType.swift
//  TestsDemo
//
//  Created by Hithakshi on 04/02/25.
//

#if canImport(UIKit)
import UIKit
#endif
// MARK: - Presentation Types
public enum PresentationType {
    case push
    case present(modalPresentationStyle: UIModalPresentationStyle = .automatic)
    case presentWith(presenter: UIViewController, modalPresentationStyle: UIModalPresentationStyle = .automatic)
    case embed(in: UIViewController, containerView: UIView)
    case root(window: UIWindow)
    case custom
}
