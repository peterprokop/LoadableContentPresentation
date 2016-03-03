import UIKit

public protocol ScrollableContentViewContainerType: LoadableContentViewPresenterType {
    typealias ScrollViewType: UIScrollView
    
    var scrollableContentView: ScrollViewType { get }
}

///Wraps LoadableContentView adding loading more functionality
public protocol PaginatableContentViewPresenterType: class, ContentLoadingStatefull {
    typealias ContentViewType: ScrollableContentViewContainerType
    
    /// Content presenter that presents view in a scroll view
    var contentViewPresenter: ContentViewType { get }
    
    /// Progress view to display when loading next page
    var paginationProgressView: LoadingProgressView { get set }
    
    /// Container that should hold `paginationProgressView`.
    var paginationProgressViewContainer: UIView { get set }
    
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool
    func endLoading(loadedContentSize: Int, error: ErrorType?)
    
    func beginLoadingMoreIfNeeded(loading: (offset: Int, limit: Int)->()) -> Bool
    func endLoadingMore(loadedContentSize: Int, error: ErrorType?)
    
    func updateContent()
    
    func shouldLoadMoreContent() -> Bool
    
    var pagination: Pagination { get set }
    
    func didEnterLoadingMoreState()
    func didExitLoadingMoreState()
}

public struct Pagination {
    public private(set) var offset: Int
    public let limit: Int
}

extension PaginatableContentViewPresenterType {

    public func stateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        delegate?.contentLoadingStateDidChange(from, to: to)
    }

}

extension ContentLoadingStateTransitionDelegate where Self: PaginatableContentViewPresenterType {
    
    public func contentLoadingStateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool {
        switch (from, to) {
        case
        (.LoadingMore, _), (.LoadedMore, _), (_, .LoadingMore), (_, .LoadedMore):
            return false
        default:
            return self.delegate?.contentLoadingStateWillChange(from, to: to) ?? true
        }
    }
    
    public func contentLoadingStateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        switch (from, to) {
        case (.LoadingMore, _), (.LoadedMore, _), (_, .LoadingMore), (_, .LoadedMore):
            return
        default:
            self.delegate?.contentLoadingStateDidChange(from, to: to)
        }
    }

}

extension PaginatableContentViewPresenterType {

    public var stateMachine: StateMachine<ContentLoadingState> {
        return contentViewPresenter.stateMachine
    }
    
    public var currentState: ContentLoadingState {
        return stateMachine.state
    }
    
    func setupInitialState() {
        contentViewPresenter.setupInitialState()
        
        stateMachine.addTransitionObserver { [unowned self] in

            //we want to handle only loading more state here
            //other states will be handled in observer of contained content presenter
            switch ($0.from, $0.to) {
            case (.LoadingMore, _), (.LoadedMore, _), (_, .LoadingMore), (_, .LoadedMore):
                break
            default:
                return
            }

            var shouldProceed = true
            if let delegate = self.delegate where !delegate.contentLoadingStateWillChange($0.from, to: $0.to) {
                shouldProceed = false
            }

            if shouldProceed {
                switch $0.from {
                case .LoadingMore:
                    self.didExitLoadingMoreState()
                default: break
                }
                
                switch $0.to {
                case .LoadingMore:
                    self.didEnterLoadingMoreState()
                default:
                    break
                }
            }
            
            self.stateDidChange($0.from, to: $0.to)
        }
        
        paginationProgressViewContainer.view.disappear()
    }
    
    public func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool {
        return self.contentViewPresenter.beginLoadingIfNeeded(loading)
    }
    
    public func endLoading(loadedContentSize: Int, error: ErrorType?) {
        pagination.offset += loadedContentSize
        self.contentViewPresenter.endLoading(loadedContentSize > 0, error: error)
    }
    
    public func beginLoadingMoreIfNeeded(loading: (offset: Int, limit: Int)->()) -> Bool {
        guard shouldLoadMoreContent() else { return false }
        
        do {
            if try stateMachine.tryState(.LoadingMore) {
                loading(offset: pagination.offset, limit: pagination.limit)
                return true
            }
        } catch { print(error) }
        return false
    }
    
    public func endLoadingMore(loadedContentSize: Int, error: ErrorType?) {
        do {
            pagination.offset += loadedContentSize
            let nextState: ContentLoadingState = error != nil ? .Failed(error!) : loadedContentSize > 0 ? .LoadedMore : .NoContent
            try stateMachine.tryState(nextState)
            updateContent()
        }
        catch { print(error) }
    }
    
    func didEnterLoadingMoreState() {
        paginationProgressView.startAnimating()
        paginationProgressViewContainer.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        paginationProgressViewContainer.disappear(animated: true) {
            self.paginationProgressView.stopAnimating()
        }
    }
    
    public func updateContent() {
        contentViewPresenter.updateContent()
    }
  
    public func shouldLoadMoreContent() -> Bool {
        let contentOffset = contentViewPresenter.scrollableContentView.contentOffset.y
        let contentViewHeight = contentViewPresenter.scrollableContentView.bounds.size.height
        
        let contentHeight = contentViewPresenter.scrollableContentView.contentSize.height
        let loadingMoreProgressViewContainerHeight = CGRectGetHeight(paginationProgressViewContainer.view.bounds)
        
        return contentOffset > max(0, contentHeight - contentViewHeight) + loadingMoreProgressViewContainerHeight
    }
    
    public var noContentView: NoContentView {
        get {
            return contentViewPresenter.noContentView
        }
        set {
            contentViewPresenter.noContentView = newValue
        }
    }
    
    public var contentView: ContentView {
        return contentViewPresenter.contentView
    }
    
    public var loadingProgressView: LoadingProgressView {
        get {
            return contentViewPresenter.loadingProgressView
        }
        set {
            contentViewPresenter.loadingProgressView = newValue
        }
    }

}
