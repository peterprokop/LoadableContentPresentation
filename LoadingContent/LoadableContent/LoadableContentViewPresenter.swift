//MARK: - Plain Views

extension UIView: ContentView {
    public func updateContent() {
    }
}

public class LoadableContentViewPresenter: LoadableContentViewPresenterType {
    
    public let contentView: ContentView
    
    public var noContentView: UIView {
        didSet {
            noContentView.alpha = oldValue.alpha
        }
    }
    
    public var errorView: ErrorView {
        didSet {
            errorView.view.alpha = oldValue.view.alpha
        }
    }
    public var loadingProgressView: LoadingProgressView {
        didSet {
            loadingProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    public private(set) var stateMachine: StateMachine<ContentLoadingState> = StateMachine(initialState: .Initial)
    
    public var delegate: ContentLoadingStateTransitionDelegate?
    
    public init(contentView: ContentView, noContentView: UIView, errorView: ErrorView, loadingProgressView: LoadingProgressView) {
        self.contentView = contentView
        self.noContentView = noContentView
        self.errorView = errorView
        self.loadingProgressView = loadingProgressView
        
        setupInitialState()
    }
    
}
