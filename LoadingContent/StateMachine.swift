import Foundation

//For types that can be matched with ~= operator.
protocol Matchable {
    @warn_unused_result
    func ~=(lhs: Self, rhs: Self) -> Bool
}

protocol State: Matchable {
    func shouldTransition(toState: Self) -> Should<Self>
}

enum Should<T>{
    case Continue
    case Abort(ErrorType?)
    case Redirect(T)
    case TryRedirect(T) //redirect will fail if it's not a valid transition
}

enum StateError: ErrorType, CustomStringConvertible {
    case InvalidStateTransition(State, State)
    
    var description: String {
        switch self {
        case let .InvalidStateTransition(from, to):
            return "Invalid state transition from \(from) to \(to)"
        }
    }
}

class StateMachine<T: State> {
    typealias TransitionObservation = ((from: T, to: T) -> ())
    
    var state: T {
        return _state
    }
    
    func tryState(newState: T) throws -> Bool {
        guard running else { return false }
        
        switch self.state.shouldTransition(newState) {
        case .Continue:
            _state = newState
            return true
        case let .Redirect(redirectState):
            _state = newState
            _state = redirectState
            return true
        case let .TryRedirect(redirectState):
            _state = newState
            return try tryState(redirectState)
        case let .Abort(error?):
            throw error
        case .Abort:
            return false
        }
    }
    
    private var _state: T {
        didSet {
            transitionObservers.forEach {
                $0(from: oldValue, to: _state)
            }
        }
    }
    
    private var transitionObservers: [(from: T, to: T) -> ()]
    
    init(initialState:T, observer: (from: T, to: T) -> () = { _ in }) {
        _state = initialState
        self.transitionObservers = [observer]
    }
    
    func addTransitionObserver(observer: (from: T, to: T) -> ()) {
        self.transitionObservers.append(observer)
    }
    
    private(set) var running: Bool = true
    
    func pause() {
        running = false
    }
    
    func resume() {
        running = true
    }
}

protocol Statefull {
    typealias StateType: State
    var stateMachine: StateMachine<StateType> { get }
    func stateDidChange(from: StateType, to: StateType)
}

