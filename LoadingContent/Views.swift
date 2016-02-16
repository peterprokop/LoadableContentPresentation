import UIKit

//MARK: Common protocols

public protocol AnimatedAppearance {
    func appear(animated animated: Bool, completion:()->())
    func disappear(animated animated: Bool, completion:()->())
}

extension AnimatedAppearance where Self: AnyView {
    public func appear(animated animated: Bool = false, completion:()->() = { }) {
        self.view.appear(animated: animated, completion: completion)
    }
    
    public func disappear(animated animated: Bool = false, completion:()->() = { }) {
        self.view.disappear(animated: animated, completion: completion)
    }
}

public protocol AnyView: class {
    var view: UIView { get }
}

extension UIView: AnyView {
    public var view: UIView {
        return self
    }
}

public protocol LoadingProgressView: AnyView, AnimatedAppearance {
    func startAnimating()
    func stopAnimating()
}

public protocol ErrorView: AnyView, AnimatedAppearance {
    var error: ErrorType? { get set }
}

public protocol ContentView: AnyView, AnimatedAppearance {
    func updateContent()
}

extension UIActivityIndicatorView: LoadingProgressView { }

extension UIView {
    public func appear(animated animated: Bool = false, completion:()->() = { }) {
        if animated {
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.alpha = 1.0
                }, completion: { _ in completion() })
        }
        else {
            alpha = 1.0
            completion()
        }
    }
    
    public func disappear(animated animated: Bool = false, completion:()->() = { }) {
        if animated {
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.alpha = 0.0
                }, completion: {_ in completion() })
        }
        else {
            alpha = 0.0
            completion()
        }
    }
}
