import UIKit

extension LoadableContentTableViewPresenter: ScrollableContentViewContainerType {
    public var scrollableContentView: UITableView {
        return tableView
    }
}

extension PaginatableContentViewPresenterType where ContentViewType.ScrollViewType == UITableView {
    
    public func didEnterLoadingMoreState() {
        contentViewPresenter.scrollableContentView.tableFooterView = paginationProgressViewContainer.view
        
        paginationProgressView.startAnimating()
        paginationProgressViewContainer.appear(animated: true)
    }
    
    public func didExitLoadingMoreState() {
        
        contentViewPresenter.scrollableContentView.tableFooterView = UIView()
        
        //to fix content offset after removing footer
        switch stateMachine.state {
        case .LoadedMore:
            
            var offset = contentViewPresenter.scrollableContentView.contentOffset
            if offset.y > 0 {
                offset.y += CGRectGetHeight(paginationProgressViewContainer.view.bounds)
                self.contentViewPresenter.scrollableContentView.contentOffset = offset
            }
            
        case .NoContent, .Failed:
            
            let offset = contentViewPresenter.scrollableContentView.contentOffset
            if offset.y > 0 && offset.y > contentViewPresenter.scrollableContentView.contentSize.height {
                var newOffset = offset
                newOffset.y += CGRectGetHeight(paginationProgressViewContainer.view.bounds)
                
                self.contentViewPresenter.scrollableContentView.contentOffset = newOffset
                self.contentViewPresenter.scrollableContentView.setContentOffset(offset, animated: true)
            }
            
        default: break;
        }
        
        paginationProgressViewContainer.view.disappear(animated: false) {
            self.paginationProgressView.stopAnimating()
        }
    }
    
}

public class PaginatableContentTableViewPresenter: PaginatableContentViewPresenterType, ContentLoadingStateTransitionDelegate {
    
    public var contentViewPresenter: LoadableContentTableViewPresenter {
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
    
    public let content: LoadableContentTableViewPresenter
    
    public var pagination: Pagination
    
    weak public var delegate: ContentLoadingStateTransitionDelegate? {
        didSet {
            content.delegate = self
        }
    }
    
    public init(content: LoadableContentTableViewPresenter, paginationProgressViewContainer: UIView, paginationProgressView: LoadingProgressView, offset: Int = 0, limit: Int = 25) {
        self.content = content
        self.paginationProgressViewContainer = paginationProgressViewContainer
        self.paginationProgressView = paginationProgressView
        self.pagination = Pagination(offset: offset, limit: limit)
        
        setupInitialState()
    }
    
}
