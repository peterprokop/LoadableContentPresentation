import Foundation

enum ContentLoadingState: State {
    
    case Initial
    case Loading
    case Loaded
    case Refreshing
    case LoadingMore
    case LoadedMore
    case NoContent
    case Failed(ErrorType)
    
    func shouldTransition(toState: ContentLoadingState) -> Should<ContentLoadingState> {
        switch (self, toState) {
            
        case (.Initial, .Loading):
            return .Continue

        case (.Loading, .Loaded), (.Loading, .NoContent), (.Loading, .Failed):
            return .Continue
        
        case (.Loaded, .Refreshing), (.Loaded, .LoadingMore):
            return .Continue
            
        case (.NoContent, .Loading):
            return .Continue
        
        case (.Failed, .Loading):
            return .Continue
            
        case (.Refreshing, .Loaded):
            return .Continue
            
        case (.Refreshing, .NoContent), (.Refreshing, .Failed):
            return .Redirect(.Loaded)
            
        case (.LoadingMore, .LoadedMore), (.LoadingMore, .NoContent), (.LoadingMore, .Failed):
            return .Redirect(.Loaded)
            
        case (.NoContent, .LoadingMore), (.Failed, .LoadingMore), (.Refreshing, .LoadingMore):
            return .Abort(nil) //just do nothing
            
        default:
            if case toState = self {
                return .Abort(nil)
            }
            else {
                return .Abort(StateError.InvalidStateTransition(self, toState))
            }
        }
    }
}

func ~=(lhs: ContentLoadingState, rhs: ContentLoadingState) -> Bool {
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

protocol ContentLoadingStateTransitionDelegate: class {
    ///If returns true then view will peroperm it's default behaviour for this state transition. Default implementation returns true.
    func stateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool

    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState)
}

extension ContentLoadingStateTransitionDelegate {
    func stateWillChange(from: ContentLoadingState, to: ContentLoadingState) -> Bool {
        return true
    }
}

protocol ContentLoadingStatefull: Statefull {
    var stateMachine: StateMachine<ContentLoadingState> { get }
    func stateDidChange(from: ContentLoadingState, to: ContentLoadingState)
    
    weak var delegate: ContentLoadingStateTransitionDelegate? { get set }
    
    var currentState: ContentLoadingState { get }
}

