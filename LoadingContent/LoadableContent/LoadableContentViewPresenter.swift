import UIKit

extension UIView: ContentView {
    public func updateContent() {
    }
}

public class LoadableContentViewPresenter: LoadableContentViewPresenterType {
    
    public let contentView: ContentView
    
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
    
    public init(contentView: ContentView, noContentView: NoContentView, loadingProgressView: LoadingProgressView) {
        self.contentView = contentView
        self.noContentView = noContentView
        self.loadingProgressView = loadingProgressView
        
        setupInitialState()
    }
    
}
