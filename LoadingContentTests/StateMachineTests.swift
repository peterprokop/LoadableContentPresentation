import XCTest
@testable import LoadingContent

class StateMachineTests: XCTestCase {
    
    static let error = NSError(domain: "", code: 0, userInfo: nil)
    
    enum TestState: State {
        case Initial
        case NextState
        case FinalState
        case InvalidState
        
        func shouldTransition(toState: TestState) -> Should<TestState> {
            switch (self, toState) {
            case (.Initial, .NextState):
                return .Continue
            case (.Initial, .InvalidState):
                return .Redirect(.NextState)
            case (.Initial, .FinalState):
                return .TryRedirect(.InvalidState)
            case (.NextState, .InvalidState):
                return .Abort(nil)
            default:
                return .Abort(StateMachineTests.error)
            }
        }
    }
    
    func testThatItCallsTransitionObservers() {
        
        //given
        var firstObserverCalled = false
        var secondObserverCalled = false
        let sut = StateMachine<TestState>(initialState: .Initial) { (from, to) -> () in
            firstObserverCalled = true
        }
        sut.addTransitionObserver { (from, to) -> () in
            secondObserverCalled = true
        }
        
        //when
        try! sut.tryState(.NextState)
        
        //then
        XCTAssertTrue(firstObserverCalled)
        XCTAssertTrue(secondObserverCalled)
    }
    
    func testThatItContinuesToState() {
        let sut = StateMachine<TestState>(initialState: .Initial)

        try! sut.tryState(.NextState)

        if case sut.state = TestState.NextState {} else {
            XCTFail()
        }
    }
    
    func testThatItRedirectsToStateThroughOriginalState() {
        var redirectedToIntermediateState = false
        let sut = StateMachine<TestState>(initialState: .Initial) { (from, to) in
            if case to = TestState.InvalidState, case from = TestState.Initial {
                redirectedToIntermediateState = true
            }
        }
        try! sut.tryState(.InvalidState)
        
        if case sut.state = TestState.NextState {} else {
            XCTFail()
        }
        
        XCTAssertTrue(redirectedToIntermediateState)
    }
    
    func testThatItAbortsInvalidRedirectThrowingError() {
        let sut = StateMachine<TestState>(initialState: .Initial)
        
        do { try sut.tryState(.FinalState) }
        catch { XCTAssertEqual(error as NSError, StateMachineTests.error) }
        
        if case sut.state = TestState.FinalState {} else {
            XCTFail()
        }
    }
    
    func testThatItAbortsTransitionThrowingError() {
        let sut = StateMachine<TestState>(initialState: .Initial)
        
        do {
            try sut.tryState(.NextState)
            try sut.tryState(.FinalState)
        }
        catch {
            XCTAssertEqual(error as NSError, StateMachineTests.error)
        }
     
        if case sut.state = TestState.NextState {} else {
            XCTFail()
        }

    }
    
    func testThatItAbortsTransitionSilently() {
        let sut = StateMachine<TestState>(initialState: .Initial)
        
        do {
            try sut.tryState(.NextState)
            try sut.tryState(.InvalidState)
        }
        catch {
            XCTFail()
        }
        
        if case sut.state = TestState.NextState {} else {
            XCTFail()
        }
    }
    
}


