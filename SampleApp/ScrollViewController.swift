import UIKit
import LoadableContentPresentation

class StringContentView: UIView {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    lazy var noContentView: UIView = {
        let view = UIView(frame: self.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.backgroundColor = UIColor.grayColor()
        self.addSubview(view)
        return view
    }()
    
    lazy var errorView: UIView = {
        let view = UIView(frame: self.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.backgroundColor = UIColor.redColor()
        self.addSubview(view)
        return view
    }()
    
    lazy var loadingProgressView: LoadingProgressView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        view.sizeToFit()
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
        view.center = CGPoint(x: CGRectGetMidX(self.bounds), y: CGRectGetMidY(self.bounds))
        self.addSubview(view)
        return view
    }()

    lazy var content: LoadableContentViewPresenter = {
        return LoadableContentViewPresenter(contentView: self.scrollView, noContentView: self.noContentView, loadingProgressView: self.loadingProgressView)
    }()
}


class ScrollViewController: UIViewController {
    
    @IBOutlet weak var contentView: StringContentView!
    
    var rootView: StringContentView {
        return view as! StringContentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        rootView.content.beginLoadingIfNeeded { () -> () in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 1), dispatch_get_main_queue()) {
                self.loadedContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
                
                self.rootView.label.text = self.loadedContent
                self.rootView.content.endLoading(true, error: nil)
            }
        }
    }
    
    var loadedContent: String?
    
}
