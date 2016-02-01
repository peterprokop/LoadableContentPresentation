import UIKit

protocol ScrollableContentViewContainerType: LoadableContentViewPresenterType {
    typealias ScrollableContentViewType: UIScrollView
    
    var scrollableContentView: ScrollableContentViewType { get }
}

///Wraps LoadableContentView adding loading more functionality
protocol PaginatableContentViewPresenterType: class, ContentLoadingStatefull {
    typealias ContentViewType: ScrollableContentViewContainerType
    
    var scrollableContentViewContainer: ContentViewType { get }
    
    var paginationProgressView: LoadingProgressView { get set }
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

struct Pagination {
    var offset: Int
    let limit: Int
}

extension PaginatableContentViewPresenterType {

    //TODO: have a dedicated state machine that handles loading more state
    var stateMachine: StateMachine<ContentLoadingState> {
        return scrollableContentViewContainer.stateMachine
    }
    
    var currentState: ContentLoadingState {
        return stateMachine.state
    }
    
    func setupInitialState() {
        scrollableContentViewContainer.setupInitialState()
        
        stateMachine.addTransitionObserver { [unowned self] in

            //we want to handle only loading more state here
            switch ($0.from, $0.to) {
            case
                (.LoadingMore, _),
                (.LoadedMore, _),
                (_, .LoadingMore),
                (_, .LoadedMore):
                break
            default:
                return
            }

            var shouldProceed = true
            if let delegate = self.delegate where !delegate.stateWillChange($0.from, to: $0.to) {
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
    
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool {
        return self.scrollableContentViewContainer.beginLoadingIfNeeded(loading)
    }
    
    func endLoading(loadedContentSize: Int, error: ErrorType?) {
        pagination.offset += loadedContentSize
        self.scrollableContentViewContainer.endLoading(loadedContentSize > 0, error: error)
    }
    
    func beginLoadingMoreIfNeeded(loading: (offset: Int, limit: Int)->()) -> Bool {
        guard shouldLoadMoreContent() else { return false }
        
        do {
            if try stateMachine.tryState(.LoadingMore) {
                loading(offset: pagination.offset, limit: pagination.limit)
                return true
            }
        } catch { print(error) }
        return false
    }
    
    func endLoadingMore(loadedContentSize: Int, error: ErrorType?) {
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
        paginationProgressViewContainer.view.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        paginationProgressViewContainer.view.disappear(animated: true) {
            self.paginationProgressView.stopAnimating()
        }
    }
    
    func updateContent() {
        scrollableContentViewContainer.updateContent()
    }
  
    func shouldLoadMoreContent() -> Bool {
        let contentOffset = scrollableContentViewContainer.scrollableContentView.contentOffset.y
        let contentViewHeight = scrollableContentViewContainer.scrollableContentView.bounds.size.height
        
        let contentHeight = scrollableContentViewContainer.scrollableContentView.contentSize.height
        let loadingMoreProgressViewContainerHeight = CGRectGetHeight(paginationProgressViewContainer.view.bounds)
        
        return contentOffset > max(0, contentHeight - contentViewHeight) + loadingMoreProgressViewContainerHeight
    }
    
    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        delegate?.stateDidChange(from, to: to)
    }
    
}

//MARK: - Table Views

extension PaginatableContentViewPresenterType where
    ContentViewType.ScrollableContentViewType == UITableView
{
    
    func didEnterLoadingMoreState() {
        scrollableContentViewContainer.scrollableContentView.tableFooterView = paginationProgressViewContainer.view
        
        paginationProgressView.startAnimating()
        paginationProgressViewContainer.view.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        
        scrollableContentViewContainer.scrollableContentView.tableFooterView = UIView()
        
        //to fix content offset after removing footer
        switch stateMachine.state {
        case .LoadedMore:
            
            var offset = scrollableContentViewContainer.scrollableContentView.contentOffset
            if offset.y > 0 {
                offset.y += CGRectGetHeight(paginationProgressViewContainer.view.bounds)
                self.scrollableContentViewContainer.scrollableContentView.contentOffset = offset
            }
            
        case .NoContent, .Failed:
            
            let offset = scrollableContentViewContainer.scrollableContentView.contentOffset
            if offset.y > 0 && offset.y > scrollableContentViewContainer.scrollableContentView.contentSize.height {
                var newOffset = offset
                newOffset.y += CGRectGetHeight(paginationProgressViewContainer.view.bounds)
                
                self.scrollableContentViewContainer.scrollableContentView.contentOffset = newOffset
                self.scrollableContentViewContainer.scrollableContentView.setContentOffset(offset, animated: true)
            }
            
        default: break;
        }
        
        paginationProgressViewContainer.view.disappear(animated: false) {
            self.paginationProgressView.stopAnimating()
        }
    }
    
}

class PaginatableContentTableViewPresenter: PaginatableContentViewPresenterType {
    
    var scrollableContentViewContainer: LoadableContentTableViewPresenter {
        return content
    }
    
    var paginationProgressViewContainer: UIView {
        didSet {
            paginationProgressViewContainer.alpha = oldValue.alpha
        }
    }
    
    var paginationProgressView: LoadingProgressView {
        didSet {
            paginationProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    let content: LoadableContentTableViewPresenter
    
    var pagination: Pagination
    
    weak var delegate: ContentLoadingStateTransitionDelegate? {
        didSet {
            content.delegate = delegate
        }
    }

    init(content: LoadableContentTableViewPresenter, paginationProgressViewContainer: UIView, paginationProgressView: LoadingProgressView, offset: Int = 0, limit: Int = 25) {
        self.content = content
        self.paginationProgressViewContainer = paginationProgressViewContainer
        self.paginationProgressView = paginationProgressView
        self.pagination = Pagination(offset: offset, limit: limit)
    }
    
}

extension LoadableContentTableViewPresenter: ScrollableContentViewContainerType {
    var scrollableContentView: UITableView {
        return tableView
    }
}

//MARK: - Collection Views

extension PaginatableContentViewPresenterType where
    ContentViewType.ScrollableContentViewType == UICollectionView
{
    
    func didEnterLoadingMoreState() {
        
        let lastSection = scrollableContentViewContainer.scrollableContentView.numberOfSections() - 1
        let indexPath = NSIndexPath(index: lastSection)
        let layout = scrollableContentViewContainer.scrollableContentView.collectionViewLayout
        let kind = UICollectionElementKindSectionFooter
        
        //to fix footer frame with added activity indicator
        if let
            frame = layout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: indexPath)?.frame,
            superview = paginationProgressViewContainer.view.superview {
                
                superview.frame = frame
                paginationProgressViewContainer.view.frame = superview.bounds
        }
        
        stateMachine.pause()
        invalidateCollectionView(scrollableContentViewContainer.scrollableContentView)
        stateMachine.resume()
        
        paginationProgressView.startAnimating()
        paginationProgressViewContainer.view.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        stateMachine.pause()
        invalidateCollectionView(scrollableContentViewContainer.scrollableContentView)
        stateMachine.resume()

        paginationProgressViewContainer.view.disappear(animated: false) {
            self.paginationProgressView.stopAnimating()
        }
    }
    
}

///Invalidates coolection view footers
private func invalidateCollectionView(collectionView: UICollectionView) {
    let context = invalidationContextToUpdateLoadingMoreSupplementaryView(collectionView)
    collectionView.collectionViewLayout.invalidateLayoutWithContext(context)
}

///Creates invalidation context to invalidate footers (last and pre-last)
private func invalidationContextToUpdateLoadingMoreSupplementaryView(collectionView: UICollectionView) -> UICollectionViewLayoutInvalidationContext {
    //for some reason plain UICollectionViewFlowLayoutInvalidationContext() causes crash...
    let context = collectionView.collectionViewLayout.invalidationContextForBoundsChange(collectionView.bounds)
    let indexPaths = (max(0, collectionView.numberOfSections() - 2)..<collectionView.numberOfSections()).map({ NSIndexPath(index: $0) })
    context.invalidateSupplementaryElementsOfKind(UICollectionElementKindSectionFooter, atIndexPaths: indexPaths)
    return context
}

class PaginatableContentCollectionViewPresenter: PaginatableContentViewPresenterType {
    
    var scrollableContentViewContainer: LoadableContentCollectionViewPresenter {
        return content
    }
    
    var paginationProgressViewContainer: UIView {
        didSet {
            paginationProgressViewContainer.alpha = oldValue.alpha
        }
    }
    
    var paginationProgressView: LoadingProgressView {
        didSet {
            paginationProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    let content: LoadableContentCollectionViewPresenter
    
    var pagination: Pagination
    
    weak var delegate: ContentLoadingStateTransitionDelegate? {
        didSet {
            content.delegate = delegate
        }
    }
    
    init(content: LoadableContentCollectionViewPresenter, paginationProgressViewContainer: UIView, paginationProgressView: LoadingProgressView, offset: Int = 0, limit: Int = 25) {
        self.content = content
        self.paginationProgressViewContainer = paginationProgressViewContainer
        self.paginationProgressView = paginationProgressView
        self.pagination = Pagination(offset: offset, limit: limit)
    }
    
}

extension LoadableContentCollectionViewPresenter: ScrollableContentViewContainerType {
    var scrollableContentView: UICollectionView {
        return collectionView
    }
}

//Layout to be used by collection views with load more function. CollectionView should have footers.
class PaginatedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    @IBInspectable
    var paginationProgressViewContainerHeight: CGFloat = 0
    
    static let paginationFooterReuseIdentifier = "PaginationFooter"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareLayout() {
        collectionView?.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PaginatedCollectionViewFlowLayout.paginationFooterReuseIdentifier)
        
        super.prepareLayout()
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var attr = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
        
        //add loading indicator container height to footer in last section
        if attr != nil {
            if let
                lastSection = collectionView?.numberOfSections()
                where indexPath.section == lastSection - 1 && elementKind == UICollectionElementKindSectionFooter {
                    attr!.frame = CGRect(origin: attr!.frame.origin, size: CGSize(width: attr!.frame.size.width, height: attr!.frame.size.height + paginationProgressViewContainerHeight))
            }
        }
        else if let collectionView = collectionView {
            attr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withIndexPath: indexPath)
            attr!.frame = CGRect(origin: CGPointZero, size: CGSize(width: collectionView.bounds.size.width, height: paginationProgressViewContainerHeight))
            attr!.zIndex = 10
            return attr
        }
        
        return attr
    }
    
    override func collectionViewContentSize() -> CGSize {
        var size = super.collectionViewContentSize()
        size.height += paginationProgressViewContainerHeight
        return size
    }
    
}
