/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how operations can be composed together to form new operations.
*/

import Foundation

/**
    A subclass of `Operation` that executes zero or more operations as part of its
    own execution. This class of operation is very useful for abstracting several 
    smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
    is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.

    Additionally, `GroupOperation`s are useful if you establish a chain of dependencies, 
    but part of the chain may "loop". For example, if you have an operation that
    requires the user to be authenticated, you may consider putting the "login" 
    operation inside a group operation. That way, the "login" operation may produce
    subsequent operations (still within the outer `GroupOperation`) that will all
    be executed before the rest of the operations in the initial chain of operations.
*/
public class GroupOperation: Operation {
    private let internalQueue = OperationQueue()
    private let finishingOperation = NSBlockOperation(block: {})

    private var aggregatedErrors = [NSError]()
    
    convenience public init(operations: NSOperation...) {
        self.init(operations: operations)
    }
    
    public init(operations: [NSOperation]) {
        super.init()
        
        internalQueue.suspended = true
        
        internalQueue.delegate = self

        for operation in operations {
            internalQueue.addOperation(operation)
        }
    }
    
    override public func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
    
    override public func execute() {
        internalQueue.suspended = false
        internalQueue.addOperation(finishingOperation)
    }
    
    public func addOperation(operation: NSOperation) {
        internalQueue.addOperation(operation)
    }
    
    /**
        Note that some part of execution has produced an error.
        Errors aggregated through this method will be included in the final array 
        of errors reported to observers and to the `finished(_:)` method.
    */
    public final func aggregateError(error: NSError) {
        aggregatedErrors.append(error)
    }
    
    public func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        // For use by subclassers.
    }
}

extension GroupOperation: OperationQueueDelegate {
    final func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation) {
        assert(!finishingOperation.finished && !finishingOperation.executing, "cannot add new operations to a group after the group has completed")
        
        /*
            Some operation in this group has produced a new operation to execute.
            We want to allow that operation to execute before the group completes,
            so we'll make the finishing operation dependent on this newly-produced operation.
        */
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
    }
    
    final func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [NSError]) {
        aggregatedErrors.appendContentsOf(errors)
        
        if operation === finishingOperation {
            internalQueue.suspended = true
            finish(aggregatedErrors)
        }
        else {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
