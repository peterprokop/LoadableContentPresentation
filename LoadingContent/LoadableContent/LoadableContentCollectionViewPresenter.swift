//MARK: - Collection Views

extension UICollectionView {
    override public func updateContent() {
        reloadData()
    }
}

public class LoadableContentCollectionViewPresenter: LoadableContentViewPresenterType {
    
    let collectionView: UICollectionView
    
    public var contentView: ContentView {
        return collectionView
    }
    
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
    
    public init(collectionView: UICollectionView, noContentView: UIView, errorView: ErrorView, loadingProgressView: LoadingProgressView) {
        self.collectionView = collectionView
        self.noContentView = noContentView
        self.errorView = errorView
        self.loadingProgressView = loadingProgressView
    }
    
}
