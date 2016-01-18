import UIKit

protocol ScrollableContentViewContainerType: LoadableContentViewType {
    typealias ScrollableContentViewType: UIScrollView
    
    var scrollableContentView: ScrollableContentViewType { get }
}

///Wraps LoadableContentView adding loading more functionality
protocol MoreLoadableContentViewType: class, ContentLoadingStatefull {
    typealias ContentViewType: ScrollableContentViewContainerType
    
    var scrollableContentViewContainer: ContentViewType { get }
    
    var loadingMoreProgressView: LoadingProgressView { get }
    var loadingMoreProgressViewContainer: AnyView { get }
    
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool
    func endLoading(hasContent: Bool, contentSize: Int, error: ErrorType?)
    
    func beginLoadingMoreIfNeeded(loading: (offset: Int, limit: Int)->()) -> Bool
    func endLoadingMore(hasMoreContent: Bool, hasContent: Bool, loadedContentSize: Int, error: ErrorType?)
    
    func reloadData()
    
    func shouldLoadMoreContent() -> Bool
    
    var pagination: Pagination { get set }
    
    func didEnterLoadingMoreState()
    func didExitLoadingMoreState()
}

struct Pagination {
    var offset: Int
    let limit: Int
}

extension MoreLoadableContentViewType
{

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
        
        loadingMoreProgressViewContainer.view.disappear()
    }
    
    func beginLoadingIfNeeded(@noescape loading: ()->()) -> Bool {
        return self.scrollableContentViewContainer.beginLoadingIfNeeded(loading)
    }
    
    func endLoading(hasContent: Bool, contentSize: Int, error: ErrorType?) {
        updatePagination(hasContent, itemsCount: contentSize)
        scrollableContentViewContainer.endLoading(hasContent, error: error)
    }
    
    func beginLoadingMoreIfNeeded(loading: (offset: Int, limit: Int)->()) -> Bool {
        guard shouldLoadMoreContent() else { return false }
        
        do {
            if try stateMachine.tryState(.LoadingMore) {
                loading(offset: pagination.offset, limit: pagination.limit)
                return true
            }
        } catch {
            print(error)
        }
        return false
    }
    
    func endLoadingMore(hasMoreContent: Bool, hasContent: Bool, loadedContentSize: Int, error: ErrorType?) {
        do {
            updatePagination(hasMoreContent, itemsCount: loadedContentSize)
            try stateMachine.tryState(error.map({ .Failed($0) }) ?? (hasContent ? .LoadedMore : .NoContent) /* content.map({ _ in .LoadedMore }) ?? .NoContent*/)
            reloadData()
        }
        catch { print(error) }
    }
    
    private func updatePagination(loadedContent: Bool, itemsCount: Int) {
        if loadedContent {
            pagination.offset += itemsCount
        }
    }
    
    func didEnterLoadingMoreState() {
        loadingMoreProgressView.startAnimating()
        loadingMoreProgressViewContainer.view.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        loadingMoreProgressViewContainer.view.disappear(animated: true) {
            self.loadingMoreProgressView.stopAnimating()
        }
    }
    
    func reloadData() {
        scrollableContentViewContainer.reloadData()
    }
  
    func shouldLoadMoreContent() -> Bool {
        let contentOffset = scrollableContentViewContainer.scrollableContentView.contentOffset.y
        let contentViewHeight = scrollableContentViewContainer.scrollableContentView.bounds.size.height
        
        let contentHeight = scrollableContentViewContainer.scrollableContentView.contentSize.height
        let loadingMoreProgressViewContainerHeight = CGRectGetHeight(loadingMoreProgressViewContainer.view.bounds)
        
        return contentOffset > max(0, contentHeight - contentViewHeight) + loadingMoreProgressViewContainerHeight
    }
    
    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        delegate?.stateDidChange(from, to: to)
    }
    
}

//MARK: - Table Views

extension MoreLoadableContentViewType where
    ContentViewType.ScrollableContentViewType == UITableView
{
    
    func didEnterLoadingMoreState() {
        scrollableContentViewContainer.scrollableContentView.tableFooterView = loadingMoreProgressViewContainer.view
        
        loadingMoreProgressView.startAnimating()
        loadingMoreProgressViewContainer.view.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        
        scrollableContentViewContainer.scrollableContentView.tableFooterView = UIView()
        
        //to fix content offset after removing footer
        switch stateMachine.state {
        case .LoadedMore:
            
            var offset = scrollableContentViewContainer.scrollableContentView.contentOffset
            if offset.y > 0 {
                offset.y += CGRectGetHeight(loadingMoreProgressViewContainer.view.bounds)
                self.scrollableContentViewContainer.scrollableContentView.contentOffset = offset
            }
            
        case .NoContent, .Failed:
            
            let offset = scrollableContentViewContainer.scrollableContentView.contentOffset
            if offset.y > 0 && offset.y > scrollableContentViewContainer.scrollableContentView.contentSize.height {
                var newOffset = offset
                newOffset.y += CGRectGetHeight(loadingMoreProgressViewContainer.view.bounds)
                
                self.scrollableContentViewContainer.scrollableContentView.contentOffset = newOffset
                self.scrollableContentViewContainer.scrollableContentView.setContentOffset(offset, animated: true)
            }
            
        default: break;
        }
        
        loadingMoreProgressViewContainer.view.disappear(animated: false) {
            self.loadingMoreProgressView.stopAnimating()
        }
    }
    
}

class MoreLoadableContentTableView: MoreLoadableContentViewType {
    
    var scrollableContentViewContainer: LoadableContentTableView {
        return content
    }
    
    var loadingMoreProgressViewContainer: AnyView
    var loadingMoreProgressView: LoadingProgressView
    
    var content: LoadableContentTableView
    var pagination: Pagination
    
    weak var delegate: ContentLoadingStateTransitionDelegate? {
        didSet {
            content.delegate = delegate
        }
    }

    init(content: LoadableContentTableView, loadingMoreProgressViewContainer: UIView, loadingMoreProgressView: LoadingProgressView, offset: Int = 0, limit: Int = 25) {
        self.content = content
        self.loadingMoreProgressViewContainer = loadingMoreProgressViewContainer
        self.loadingMoreProgressView = loadingMoreProgressView
        self.pagination = Pagination(offset: offset, limit: limit)
    }
    
}

extension LoadableContentTableView: ScrollableContentViewContainerType {
    var scrollableContentView: UITableView {
        return tableView
    }
}

//MARK: - Collection Views

extension MoreLoadableContentViewType where
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
            superview = loadingMoreProgressViewContainer.view.superview {
                
                superview.frame = frame
                loadingMoreProgressViewContainer.view.frame = superview.bounds
        }
        
        stateMachine.pause()
        invalidateCollectionView(scrollableContentViewContainer.scrollableContentView)
        stateMachine.resume()
        
        loadingMoreProgressView.startAnimating()
        loadingMoreProgressViewContainer.view.appear(animated: true)
    }
    
    func didExitLoadingMoreState() {
        stateMachine.pause()
        invalidateCollectionView(scrollableContentViewContainer.scrollableContentView)
        stateMachine.resume()

        loadingMoreProgressViewContainer.view.disappear(animated: false) {
            self.loadingMoreProgressView.stopAnimating()
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

class MoreLoadableContentCollectionView: MoreLoadableContentViewType {
    
    var scrollableContentViewContainer: LoadableContentCollectionView {
        return content
    }
    
    var loadingMoreProgressViewContainer: AnyView
    var loadingMoreProgressView: LoadingProgressView
    
    var content: LoadableContentCollectionView
    var pagination: Pagination
    
    weak var delegate: ContentLoadingStateTransitionDelegate? {
        didSet {
            content.delegate = delegate
        }
    }
    
    init(content: LoadableContentCollectionView, loadingMoreProgressViewContainer: UIView, loadingMoreProgressView: LoadingProgressView, offset: Int = 0, limit: Int = 25) {
        self.content = content
        self.loadingMoreProgressViewContainer = loadingMoreProgressViewContainer
        self.loadingMoreProgressView = loadingMoreProgressView
        self.pagination = Pagination(offset: offset, limit: limit)
    }
    
}

extension LoadableContentCollectionView: ScrollableContentViewContainerType {
    var scrollableContentView: UICollectionView {
        return collectionView
    }
}

//Layout to be used by collection views with load more function. CollectionView should have footers.
class LoadMoreCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    @IBInspectable
    var loadingMoreProgressViewContainerHeight: CGFloat = 0
    
    static let loadMoreFooterReuseIdentifier = "LoadMoreFooter"
    
    override func prepareLayout() {
        collectionView?.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: LoadMoreCollectionViewFlowLayout.loadMoreFooterReuseIdentifier)
        
        super.prepareLayout()
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
        
        //add loading indicator container height to footer in last section
        if let attr = attr {
            if let
                lastSection = collectionView?.numberOfSections()
                where indexPath.section == lastSection - 1 && elementKind == UICollectionElementKindSectionFooter {
                    attr.frame = CGRect(origin: attr.frame.origin, size: CGSize(width: attr.frame.size.width, height: attr.frame.size.height + loadingMoreProgressViewContainerHeight))
            }
        }
        else if let collectionView = collectionView {
            let attr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withIndexPath: indexPath)
            attr.frame = CGRect(origin: CGPointZero, size: CGSize(width: collectionView.bounds.size.width, height: loadingMoreProgressViewContainerHeight))
            attr.zIndex = 10
            return attr
        }
        
        return attr
    }
    
    override func collectionViewContentSize() -> CGSize {
        var size = super.collectionViewContentSize()
        size.height += loadingMoreProgressViewContainerHeight
        return size
    }
    
}
