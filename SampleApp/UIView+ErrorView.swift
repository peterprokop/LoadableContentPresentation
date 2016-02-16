import LoadingContent

private let NSErrorAssiciatedKey = UnsafeMutablePointer<Int8>.alloc(1)

class Box<T> {
    let unbox: T
    init(value: T) {
        self.unbox = value
    }
}

extension UIView: ErrorView {
    
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