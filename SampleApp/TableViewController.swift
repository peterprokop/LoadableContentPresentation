import UIKit
import LoadingContent
import DZNEmptyDataSet

class IntsPaginatableTableView: UIView {
    
    @IBOutlet weak var tableView: UITableView!
    
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

    lazy var contentPresenter: PaginatableContentTableViewPresenter = {
        let content = LoadableContentTableViewPresenter(tableView: self.tableView, noContentView: self.tableView!.noContentView, loadingProgressView: self.loadingProgressView)
        return PaginatableContentTableViewPresenter(content: content, paginationProgressViewContainer: self.loadingMoreProgressViewContainer, paginationProgressView: self.loadingMoreProgressView, limit: 5)
    }()
    
}

class TableViewController: UIViewController, ContentLoadingStateTransitionDelegate {
    
    var rootView: IntsPaginatableTableView {
        return view as! IntsPaginatableTableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()

        rootView.tableView.emptyDataSetSource = self
        rootView.tableView.emptyDataSetDelegate = self

        rootView.contentPresenter.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
    }
    
    func loadData() {
        let limit = rootView.contentPresenter.pagination.limit
        let pageSize = limit*5
        
        rootView.contentPresenter.beginLoadingIfNeeded {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 1), dispatch_get_main_queue()) {
//                if self.loadedContent.isEmpty {
//                    self.loadedContent = [(0..<pageSize).reduce([Int](), combine: { $0.0 + [$0.1] })]
//                    self.rootView.contentPresenter.endLoading(pageSize, error: nil)
//                }
//                else {
                //simulate error when there was content previously
                self.rootView.contentPresenter.endLoading(0, error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "error desc"]))
//                }
            }
        }
    }
    
    var loadedContent = [[Int]]()

    func contentLoadingStateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool {
        print("will transition from \(from) to \(to)")
        switch to {
        case .Failed, .NoContent:
            rootView.contentPresenter.loadingProgressView.disappear(animated: true)
            rootView.contentPresenter.contentView.appear(animated: true)
            rootView.contentPresenter.noContentView.appear(animated: true)
            return false
        default:
            return true
        }
    }

    func contentLoadingStateDidChange(from: ContentLoadingState, to: ContentLoadingState) {
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
        
        rootView.contentPresenter.beginLoadingMoreIfNeeded { offset, limit in

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5)), dispatch_get_main_queue()) {
                let newContent = /*[[Int]]() // */[(offset..<offset+limit).reduce([Int](), combine: { $0.0 + [$0.1] })]
                self.loadedContent += newContent
                
                self.rootView.contentPresenter.endLoadingMore(limit, error: nil)
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(section)
    }
}

extension TableViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {

    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        switch self.rootView.contentPresenter.currentState {
        case .NoContent, .Failed: return true
        default: return false
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if let errorString = (scrollView.noContentView.error as? NSError)?.localizedDescription {
            return NSAttributedString(string: errorString)
        }
        return NSAttributedString(string: "No content")
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "Reload")
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        //this method recreates views
        scrollView.reloadEmptyDataSet()
        
        //need to update content presenter reference
        rootView.contentPresenter.noContentView = scrollView.noContentView
        
        loadData()
    }

}



