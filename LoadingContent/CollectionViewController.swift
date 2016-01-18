import UIKit

class IntsLoadableCollectionView: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!

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

    lazy var content: LoadableContentCollectionViewOf<[[Int]]> = {
        return LoadableContentCollectionViewOf(collectionView: self.collectionView, noContentView: self.noContentView, errorView: self.errorView, loadingProgressView: self.loadingProgressView)
    }()
}

class IntsMoreLoadableCollectionView: UIView {
    
    lazy var loadingMoreProgressView: LoadingProgressView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        view.sizeToFit()
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
        view.center = CGPoint(x: CGRectGetMidX(self.loadingMoreProgressViewContainer.bounds), y: CGRectGetMidY(self.loadingMoreProgressViewContainer.bounds))
        self.loadingMoreProgressViewContainer.addSubview(view)
        return view
    }()
    
    lazy var loadingMoreProgressViewContainer: UIView = {
        let view = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: self.bounds.size.width, height: 0)))
        view.autoresizingMask = [.FlexibleWidth]
        return view
    }()

    lazy var moreContent: MoreLoadableContentCollectionViewOf<[[Int]]> = {
        return MoreLoadableContentCollectionViewOf(content: self.contentView.content, loadingMoreProgressViewContainer: self.loadingMoreProgressViewContainer, loadingMoreProgressView: self.loadingMoreProgressView, limit: 5)
    }()

    @IBOutlet weak var contentView: IntsLoadableCollectionView!
}


class CollectionViewController: UIViewController {
    
    var rootView: IntsMoreLoadableCollectionView {
        return view as! IntsMoreLoadableCollectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        rootView.moreContent.setupInitialState()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let limit = rootView.moreContent.pagination.limit
        let pageSize = limit
        
        rootView.moreContent.beginLoadingIfNeeded {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 1), dispatch_get_main_queue()) {
                if case .Loading = self.rootView.moreContent.currentState {
                    self.loadedContent = [(0..<pageSize).reduce([Int](), combine: { $0.0 + [$0.1] })]
                }
                self.rootView.moreContent.endLoading(true, contentSize: pageSize, error: nil)
            }
        }
    }
    
    var loadedContent = [[Int]]()

}

extension CollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return loadedContent.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedContent[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        (cell.viewWithTag(1) as? UILabel)?.text = String(loadedContent[indexPath.section][indexPath.item])
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: LoadMoreCollectionViewFlowLayout.loadMoreFooterReuseIdentifier, forIndexPath: indexPath)
            //we want loading more progress view container to be placed in last section footer
            if indexPath.section == numberOfSectionsInCollectionView(collectionView) - 1 {
                view.addSubview(rootView.loadingMoreProgressViewContainer)
            }
            return view
        }
        return UICollectionReusableView()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        rootView.moreContent.beginLoadingMoreIfNeeded { offset, limit in
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 1), dispatch_get_main_queue()) {
                let newContent = /*[[Int]]() // */ [(offset..<limit+offset).reduce([Int](), combine: { $0.0 + [$0.1] })]
                self.loadedContent += newContent
                
                self.rootView.moreContent.endLoadingMore(true, hasContent: true, loadedContentSize: limit, error: nil)
            }
        }
    }

}
