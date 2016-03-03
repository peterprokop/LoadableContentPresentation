//MARK: - Collection Views

extension LoadableContentCollectionViewPresenter: ScrollableContentViewContainerType {
    public var scrollableContentView: UICollectionView {
        return collectionView
    }
}

extension PaginatableContentViewPresenterType where ContentViewType.ScrollViewType == UICollectionView {
    
    public func didEnterLoadingMoreState() {
        
        let lastSection = contentViewPresenter.scrollableContentView.numberOfSections() - 1
        let indexPath = NSIndexPath(index: lastSection)
        let layout = contentViewPresenter.scrollableContentView.collectionViewLayout
        let kind = UICollectionElementKindSectionFooter
        
        //to fix footer frame with added activity indicator
        if let
            frame = layout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: indexPath)?.frame,
            superview = paginationProgressViewContainer.view.superview {
                
                superview.frame = frame
                paginationProgressViewContainer.view.frame = superview.bounds
        }
        
        stateMachine.pause()
        invalidateCollectionView(contentViewPresenter.scrollableContentView)
        stateMachine.resume()
        
        paginationProgressView.startAnimating()
        paginationProgressViewContainer.appear(animated: true)
    }
    
    public func didExitLoadingMoreState() {
        stateMachine.pause()
        invalidateCollectionView(contentViewPresenter.scrollableContentView)
        stateMachine.resume()
        
        paginationProgressViewContainer.view.disappear(animated: false) {
            self.paginationProgressView.stopAnimating()
        }
    }
    
}

public class PaginatableContentCollectionViewPresenter: PaginatableContentViewPresenterType, ContentLoadingStateTransitionDelegate {
    
    public var contentViewPresenter: LoadableContentCollectionViewPresenter {
        return content
    }
    
    public var paginationProgressViewContainer: UIView {
        didSet {
            paginationProgressViewContainer.alpha = oldValue.alpha
        }
    }
    
    public var paginationProgressView: LoadingProgressView {
        didSet {
            paginationProgressView.view.alpha = oldValue.view.alpha
        }
    }
    
    public let content: LoadableContentCollectionViewPresenter
    
    public var pagination: Pagination
    
    weak public var delegate: ContentLoadingStateTransitionDelegate? {
        didSet {
            content.delegate = self
        }
    }
    
    public init(content: LoadableContentCollectionViewPresenter, paginationProgressViewContainer: UIView, paginationProgressView: LoadingProgressView, offset: Int = 0, limit: Int = 25) {
        self.content = content
        self.paginationProgressViewContainer = paginationProgressViewContainer
        self.paginationProgressView = paginationProgressView
        self.pagination = Pagination(offset: offset, limit: limit)
        
        setupInitialState()
    }
    
}

//Layout to be used by collection views with load more function. CollectionView should have footers.
public class PaginatedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    @IBInspectable
    public var paginationProgressViewContainerHeight: CGFloat = 0
    
    public static let paginationFooterReuseIdentifier = "PaginationFooter"
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func prepareLayout() {
        collectionView?.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PaginatedCollectionViewFlowLayout.paginationFooterReuseIdentifier)
        
        super.prepareLayout()
    }
    
    override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
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
    
    override public func collectionViewContentSize() -> CGSize {
        var size = super.collectionViewContentSize()
        size.height += paginationProgressViewContainerHeight
        return size
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
