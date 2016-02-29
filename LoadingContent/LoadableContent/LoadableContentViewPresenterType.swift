import UIKit

//MARK: - LoadableContentView

public protocol LoadableContentViewPresenterType: class, ContentLoadingStatefull {
    
    var contentView: ContentView { get }
    var noContentView: NoContentView { get set }
    var loadingProgressView: LoadingProgressView { get set }
    
    ///Starts loading using block
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool
    
    ///Complete loading. Will call `updateContent()` on `contentView`.
    func endLoading(hasContent: Bool, error: ErrorType?)
}

extension LoadableContentViewPresenterType {
    public func updateContent() {
        contentView.updateContent()
    }
    
    public func stateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        delegate?.stateDidChange(from, to: to)
    }
}

extension LoadableContentViewPresenterType {

    public var currentState: ContentLoadingState {
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
        loadingProgressView.view.disappear()
    }
    
    public func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool {
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
    
    public func endLoading(hasContent: Bool, error: ErrorType?) {
        do {
            let nextState: ContentLoadingState = error != nil ? .Failed(error!) : hasContent ? .Loaded : .NoContent
            try stateMachine.tryState(nextState)
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
        contentView.appear(animated: true)
    }
    
    private func didEnterNoContentState() {
        noContentView.appear(animated: true)
    }
    
    private func didExitNoContentState() {
        noContentView.disappear(animated: true)
    }
    
    private func didEnterErrorState() {
        noContentView.appear(animated: true)
    }
    
    private func didExitErrorState() {
        noContentView.disappear(animated: true)
    }
    
}
