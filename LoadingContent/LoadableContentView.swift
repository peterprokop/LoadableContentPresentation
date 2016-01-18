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
    var error: ErrorType! { get set }
}

protocol ContentView: AnyView {
    func reloadData()
}

extension UIActivityIndicatorView: LoadingProgressView {}

//TODO: Add refresh indicator view

//MARK: - LoadableContentView

protocol LoadableContentViewPresenterType: class, ContentLoadingStatefull {
    
    var contentView: ContentView { get }
    var noContentView: AnyView { get }
    var errorView: ErrorView { get }
    var loadingProgressView: LoadingProgressView { get }
    
    ///Starts loading using block
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool
    
    ///Complete loading. Will call realodData.
    func endLoading(hasContent: Bool, error: ErrorType?)
    
    func reloadData()
}

extension LoadableContentViewPresenterType {
    func reloadData() {
        contentView.reloadData()
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
            
            //we do not want to hande loading more state here
            switch ($0.from, $0.to) {
            case
            (.LoadingMore, _),
            (.LoadedMore, _),
            (_, .LoadingMore),
            (_, .LoadedMore):
                return
            default:
                break
            }
            
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
            try stateMachine.tryState(error.map({ .Failed($0) }) ?? (hasContent ? .Loaded : .NoContent) /*content.map({ _ in .Loaded }) ?? .NoContent*/)
            reloadData()
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
    
    var contentView: ContentView
    var noContentView: AnyView
    var errorView: ErrorView
    var loadingProgressView: LoadingProgressView
    
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
    func reloadData() {
    }
}



//MARK: - Table Views

class LoadableContentTableViewPresenter: LoadableContentViewPresenterType {
    
    var tableView: UITableView
    
    var contentView: ContentView {
        return tableView
    }
    
    var noContentView: AnyView
    var errorView: ErrorView
    var loadingProgressView: LoadingProgressView
    
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

class LoadableContentCollectionViewPresenter: LoadableContentViewPresenterType {

    var collectionView: UICollectionView
    
    var contentView: ContentView {
        return collectionView
    }
    
    var noContentView: AnyView
    var errorView: ErrorView
    var loadingProgressView: LoadingProgressView
    
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


