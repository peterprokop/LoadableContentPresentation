import UIKit

//MARK: Common protocols

protocol AnyView: class {
    var view: UIView { get }
}

extension UIView: AnyView {
    var view: UIView { return self }
}

protocol LoadingProgressView: AnyView {
    func startAnimating()
    func stopAnimating()
}

protocol ErrorView: AnyView {
    var error: ErrorType? { get set }
}

protocol ContentView: AnyView {
    func updateContent()
}

extension UIActivityIndicatorView: LoadingProgressView {}

//TODO: Add refresh indicator view

//MARK: - LoadableContentView

protocol LoadableContentViewPresenterType: class, ContentLoadingStatefull {
    
    var contentView: ContentView { get }
    var noContentView: UIView { get set }
    var errorView: ErrorView { get set }
    var loadingProgressView: LoadingProgressView { get set }
    
    ///Starts loading using block
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool
    
    ///Complete loading. Will call realodData.
    func endLoading(hasContent: Bool, error: ErrorType?)
    
    func updateContent()
}

extension LoadableContentViewPresenterType {
    func updateContent() {
        contentView.updateContent()
    }
    
    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        delegate?.stateDidChange(from, to: to)
    }
}

extension LoadableContentViewPresenterType {

    var currentState: ContentLoadingState {
        return stateMachine.state
    }

    func setupInitialState() {
        stateMachine.addTransitionObserver { [unowned self] in
            
            var shouldProceed = true
            if let delegate = self.delegate where !delegate.stateWillChange($0.from, to: $0.to) {
                shouldProceed = false
            }
            
            if shouldProceed {
                switch $0.to {
                case .Loading:
                    self.didEnterLoadingState()
                case .Loaded:
                    self.didEnterLoadedState()
                case .NoContent:
                    self.didEnterNoContentState()
                case .Failed:
                    self.didEnterErrorState()
                default: break
                }
                
                switch $0.from {
                case .Loading:
                    self.didExitLoadingState()
                case .NoContent:
                    self.didExitNoContentState()
                case .Failed:
                    self.didExitErrorState()
                default: break
                }
            }
            
            self.stateDidChange($0.from, to: $0.to)
        }
        
        contentView.view.disappear()
        noContentView.view.disappear()
        errorView.view.disappear()
        loadingProgressView.view.disappear()
    }
    
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool {
        return
            tryLoadingWithNewState(.Loading, loading: loading) ||
            tryLoadingWithNewState(.Refreshing, loading: loading)
    }
    
    private func tryLoadingWithNewState(state: ContentLoadingState, @noescape loading: ()->()) -> Bool {
        do {
            if try stateMachine.tryState(state) {
                loading()
                return true
            }
        }
        catch { print(error) }
        return false
    }
    
    func endLoading(hasContent: Bool, error: ErrorType?) {
        do {
            let nextState: ContentLoadingState = error != nil ? .Failed(error!) : hasContent ? .Loaded : .NoContent
            try stateMachine.tryState(nextState)
            errorView.error = error
            updateContent()
        }
        catch { print(error) }
    }
    
    private func didEnterLoadingState() {
        loadingProgressView.startAnimating()
        (loadingProgressView as! UIView).appear(animated: true)
    }
    
    private func didExitLoadingState() {
        (loadingProgressView as! UIView).disappear(animated: true) {
            self.loadingProgressView.stopAnimating()
        }
    }
    
    private func didEnterLoadedState() {
        contentView.view.appear(animated: true)
    }
    
    private func didEnterNoContentState() {
        noContentView.view.appear(animated: true)
    }
    
    private func didExitNoContentState() {
        noContentView.view.disappear(animated: true)
    }
    
    private func didEnterErrorState() {
        errorView.view.appear(animated: true)
    }
    
    private func didExitErrorState() {
        errorView.view.disappear(animated: true)
    }
    
}

//MARK: - Plain Views

class LoadableContentViewPresenter: LoadableContentViewPresenterType {
    
    let contentView: ContentView
    
    var noContentView: UIView {
        didSet {
            noContentView.alpha = oldValue.alpha
        }
    }
    
    var errorView: ErrorView {
        didSet {
            errorView.view.alpha = oldValue.view.alpha
        }
    }
    var loadingProgressView: LoadingProgressView {
        didSet {
            loadingProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    var stateMachine: StateMachine<ContentLoadingState> = StateMachine(initialState: .Initial)
    
    var delegate: ContentLoadingStateTransitionDelegate?
    
    init(contentView: ContentView, noContentView: UIView, errorView: ErrorView, loadingProgressView: LoadingProgressView) {
        self.contentView = contentView
        self.noContentView = noContentView
        self.errorView = errorView
        self.loadingProgressView = loadingProgressView
    }
    
}

extension UIView: ContentView {
    func updateContent() {
    }
}

//MARK: - Table Views

extension UITableView {
    override func updateContent() {
        reloadData()
    }
}

class LoadableContentTableViewPresenter: LoadableContentViewPresenterType {
    
    let tableView: UITableView
    
    var contentView: ContentView {
        return tableView
    }
    
    var noContentView: UIView {
        didSet {
            noContentView.alpha = oldValue.alpha
        }
    }
    
    var errorView: ErrorView {
        didSet {
            errorView.view.alpha = oldValue.view.alpha
        }
    }
    var loadingProgressView: LoadingProgressView {
        didSet {
            loadingProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    var stateMachine: StateMachine<ContentLoadingState> = StateMachine(initialState: .Initial)
    
    var delegate: ContentLoadingStateTransitionDelegate?

    init(tableView: UITableView, noContentView: UIView, errorView: ErrorView, loadingProgressView: LoadingProgressView) {
        self.tableView = tableView
        self.noContentView = noContentView
        self.errorView = errorView
        self.loadingProgressView = loadingProgressView
    }
    
}

//MARK: - Collection Views

extension UICollectionView {
    override func updateContent() {
        reloadData()
    }
}

class LoadableContentCollectionViewPresenter: LoadableContentViewPresenterType {

    let collectionView: UICollectionView
    
    var contentView: ContentView {
        return collectionView
    }
    
    var noContentView: UIView {
        didSet {
            noContentView.alpha = oldValue.alpha
        }
    }
    
    var errorView: ErrorView {
        didSet {
            errorView.view.alpha = oldValue.view.alpha
        }
    }
    var loadingProgressView: LoadingProgressView {
        didSet {
            loadingProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    var stateMachine: StateMachine<ContentLoadingState> = StateMachine(initialState: .Initial)
    
    var delegate: ContentLoadingStateTransitionDelegate?

    init(collectionView: UICollectionView, noContentView: UIView, errorView: ErrorView, loadingProgressView: LoadingProgressView) {
        self.collectionView = collectionView
        self.noContentView = noContentView
        self.errorView = errorView
        self.loadingProgressView = loadingProgressView
    }
    
}

extension UIView {
    func appear(animated animated: Bool = false, completion:()->() = { }) {
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
    
    func disappear(animated animated: Bool = false, completion:()->() = { }) {
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


