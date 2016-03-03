import Foundation

public enum ContentLoadingState: State {
    
    case Initial
    case Loading
    case Loaded
    case Refreshing
    case LoadingMore
    case LoadedMore
    case NoContent
    case Failed(ErrorType)
    
    public func shouldTransition(toState: ContentLoadingState) -> Should<ContentLoadingState> {
        switch (self, toState) {
            
        case (.Initial, .Loading):
            return .Continue

        case (.Loading, .Loaded), (.Loading, .NoContent), (.Loading, .Failed):
            return .Continue
        
        case (.Loaded, .Loading):
            return .Redirect(.Refreshing)

        case (.Loaded, .Refreshing), (.Loaded, .LoadingMore):
            return .Continue
            
        case (.NoContent, .Loading):
            return .Continue
        
        case (.Failed, .Loading):
            return .Continue
            
        case (.Refreshing, .Loaded):
            return .Continue
            
        case (.Refreshing, .NoContent), (.Refreshing, .Failed),
            (.LoadingMore, .LoadedMore), (.LoadingMore, .NoContent), (.LoadingMore, .Failed):
            //if we entered LoadingMore/Refreshing state then it automatically means that there is already some content
            //becase transition to LoadingMore/Refreshing enabled only from Loaded state
            //so we can just redirect back to Loaded state
            return .Redirect(.Loaded)
            
        case (.NoContent, .LoadingMore), (.Failed, .LoadingMore), (.Refreshing, .LoadingMore):
            return .Abort(nil) //just do nothing
            
        default:
            if case toState = self {
                //silently fail when transitioning to current state
                return .Abort(nil)
            }
            else {
                //disable all other kinds of transitions
                return .Abort(StateError.InvalidStateTransition(self, toState))
            }
        }
    }
}

public func ~=(lhs: ContentLoadingState, rhs: ContentLoadingState) -> Bool {
    switch (lhs, rhs) {
    case (.Initial, .Initial),
    (.Loading, .Loading),
    (.Refreshing, .Refreshing),
    (.LoadingMore, .LoadingMore),
    (.NoContent, .NoContent),
    (.Loaded, .Loaded),
    (.LoadedMore, .LoadedMore),
    (.Failed, .Failed):
        return true
    default:
        return false
    }
}

public protocol ContentLoadingStateTransitionDelegate: class {
    ///If returns true then view will peroperm it's default behaviour for this state transition. Default implementation returns true.
    func contentLoadingStateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool

    func contentLoadingStateDidChange(from: ContentLoadingState, to: ContentLoadingState)
}

extension ContentLoadingStateTransitionDelegate {
    func contentLoadingStateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool {
        return true
    }
}

public protocol ContentLoadingStatefull: Statefull {
    var stateMachine: StateMachine<ContentLoadingState> { get }
    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState)
    
    weak var delegate: ContentLoadingStateTransitionDelegate? { get set }
    
    var currentState: ContentLoadingState { get }
}

