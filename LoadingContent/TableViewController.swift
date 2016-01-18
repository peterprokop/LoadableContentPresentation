import UIKit

class MyErrorView: UIView, ErrorView {
    var error: ErrorType!
}

class IntsMoreLoadableTableView: UIView {
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var noContentView: UIView = {
        let view = UIView(frame: self.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.backgroundColor = UIColor.grayColor()
        self.addSubview(view)
        return view
    }()
    
    lazy var errorView: MyErrorView = {
        let view = MyErrorView(frame: self.bounds)
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
    
    lazy var loadingMoreProgressView: LoadingProgressView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        view.sizeToFit()
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
        view.center = CGPoint(x: CGRectGetMidX(self.loadingMoreProgressViewContainer.bounds), y: CGRectGetMidY(self.loadingMoreProgressViewContainer.bounds))
        self.loadingMoreProgressViewContainer.addSubview(view)
        return view
    }()
    
    lazy var loadingMoreProgressViewContainer: UIView = {
        let view = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: self.bounds.size.width, height: 80)))
        view.autoresizingMask = [.FlexibleWidth]
        return view
    }()

    lazy var moreContent: MoreLoadableContentTableViewPresenter = {
        let content = LoadableContentTableViewPresenter(tableView: self.tableView, noContentView: self.noContentView, errorView: self.errorView, loadingProgressView: self.loadingProgressView)
        return MoreLoadableContentTableViewPresenter(content: content, loadingMoreProgressViewContainer: self.loadingMoreProgressViewContainer, loadingMoreProgressView: self.loadingMoreProgressView, limit: 5)
    }()
    
}

class TableViewController: UIViewController, ContentLoadingStateTransitionDelegate {
    
    var rootView: IntsMoreLoadableTableView {
        return view as! IntsMoreLoadableTableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        rootView.moreContent.setupInitialState()
        rootView.moreContent.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let limit = rootView.moreContent.pagination.limit
        let pageSize = limit*5
        
        rootView.moreContent.beginLoadingIfNeeded {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 1), dispatch_get_main_queue()) {
                if self.loadedContent.isEmpty {
                    self.loadedContent = [(0..<pageSize).reduce([Int](), combine: { $0.0 + [$0.1] })]
                    self.rootView.moreContent.endLoading(true, contentSize: pageSize, error: nil)
                }
                else {
                    //simulate error when there was content previously
                    self.rootView.moreContent.endLoading(false, contentSize: 0, error: NSError(domain: "", code: 0, userInfo: nil))
                }
            }
        }
    }
    
    var loadedContent = [[Int]]()

    func stateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool {
        print("will transition from \(from) to \(to)")
        return true
    }

    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
        print("did transition from \(from) to \(to)")
    }
}

extension TableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return loadedContent.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedContent[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = String(loadedContent[indexPath.section][indexPath.row])
        return cell
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        rootView.moreContent.beginLoadingMoreIfNeeded { offset, limit in

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5)), dispatch_get_main_queue()) {
                let newContent = /*[[Int]]() // */[(offset..<offset+limit).reduce([Int](), combine: { $0.0 + [$0.1] })]
                self.loadedContent += newContent
                
                self.rootView.moreContent.endLoadingMore(true, hasContent: true, loadedContentSize: limit, error: nil)
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(section)
    }
}

