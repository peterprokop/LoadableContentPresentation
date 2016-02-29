//MARK: - Table Views

extension UITableView {
    override public func updateContent() {
        reloadData()
    }
}

public class LoadableContentTableViewPresenter: LoadableContentViewPresenterType {
    
    let tableView: UITableView
    
    public var contentView: ContentView {
        return tableView
    }
    
    public var noContentView: NoContentView {
        didSet {
            noContentView.view.alpha = oldValue.view.alpha
        }
    }
    
    public var loadingProgressView: LoadingProgressView {
        didSet {
            loadingProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    public private(set) var stateMachine: StateMachine<ContentLoadingState> = StateMachine(initialState: .Initial)
    
    public var delegate: ContentLoadingStateTransitionDelegate?
    
    public init(tableView: UITableView, noContentView: NoContentView, loadingProgressView: LoadingProgressView) {
        self.tableView = tableView
        self.noContentView = noContentView
        self.loadingProgressView = loadingProgressView
        
        setupInitialState()
    }
    
}
