import UIKit

//MARK: AnyView

public protocol AnyView: class {
    var view: UIView { get }
}

extension UIView: AnyView {
    public var view: UIView {
        return self
    }
}

//MARK: - AnimatedAppearance

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

//MARK: - ContentView

public protocol ContentView: AnyView, AnimatedAppearance {
    func updateContent()
}

//MARK: - NoContentView

public protocol NoContentView: AnyView, AnimatedAppearance {
    var error: ErrorType? { get set }
}

private let NSErrorAssiciatedKey = UnsafeMutablePointer<Int8>.alloc(1)

class Box<T> {
    let unbox: T
    init(value: T) {
        self.unbox = value
    }
}

extension UIView: NoContentView {
    
    public var error: ErrorType? {
        get {
            return boxedError?.unbox
        }
        set {
            boxedError = newValue.map(Box<ErrorType>.init)
        }
    }
    
    private var boxedError: Box<ErrorType>? {
        get {
            return objc_getAssociatedObject(self, NSErrorAssiciatedKey) as? Box<ErrorType>
        }
        set {
            objc_setAssociatedObject(self, NSErrorAssiciatedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

//MARK: - LoadingProgressView

public protocol LoadingProgressView: AnyView, AnimatedAppearance {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: LoadingProgressView { }
