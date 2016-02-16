import Foundation

//For types that can be matched with ~= operator.
public protocol Matchable {
    @warn_unused_result
    func ~=(lhs: Self, rhs: Self) -> Bool
}

public protocol State: Matchable {
    func shouldTransition(toState: Self) -> Should<Self>
}

public enum Should<T>{
    case Continue
    case Abort(ErrorType?)
    case Redirect(T)
    case TryRedirect(T) //redirect will fail if it's not a valid transition
}

public enum StateError: ErrorType, CustomStringConvertible {
    case InvalidStateTransition(State, State)
    
    public var description: String {
        switch self {
        case let .InvalidStateTransition(from, to):
            return "Invalid state transition from \(from) to \(to)"
        }
    }
}

public class StateMachine<T: State> {
    
    func tryState(newState: T) throws -> Bool {
        guard isRunning else { return false }
        
        switch self.state.shouldTransition(newState) {
        case .Continue:
            setState(newState)
            return true
        case let .Redirect(redirectState):
            setState(newState)
            setState(redirectState)
            return true
        case let .TryRedirect(redirectState):
            setState(newState)
            return try tryState(redirectState)
        case let .Abort(error?):
            throw error
        case .Abort:
            return false
        }
    }
    
    private let _isolationQueue: dispatch_queue_t
    
    private func setState(newState: T) {
        dispatch_sync(_isolationQueue) { self._state = newState }
    }
    
    public var state: T {
        var aState: T!
        dispatch_sync(_isolationQueue) { aState = self._state }
        return aState
    }
    
    private var _state: T {
        didSet {
            transitionObservers.forEach {
                $0(from: oldValue, to: _state)
            }
        }
    }
    
    private var transitionObservers: [(from: T, to: T) -> ()]
    
    public init(initialState:T, observer: (from: T, to: T) -> () = { _ in }) {
        _state = initialState
        _isolationQueue = dispatch_queue_create("\(self.dynamicType) queue", DISPATCH_QUEUE_SERIAL)
        self.transitionObservers = [observer]
    }
    
    public func addTransitionObserver(observer: (from: T, to: T) -> ()) {
        self.transitionObservers.append(observer)
    }
    
    private(set) var isRunning: Bool = true
    
    public func pause() {
        isRunning = false
    }
    
    public func resume() {
        isRunning = true
    }
}

public protocol Statefull {
    typealias StateType: State
    var stateMachine: StateMachine<StateType> { get }
    func stateDidChange(from: StateType, to: StateType)
}

