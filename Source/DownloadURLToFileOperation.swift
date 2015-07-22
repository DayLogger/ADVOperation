//
//  DownloadURLToFileOperation.swift
//  ADVOperation
//
//  Created by Tim Shadel on 7/22/15.
//  Copyright © 2015 Advanced Operation. All rights reserved.
//

import Foundation

public class DownloadURLToFileOperation: GroupOperation {
    // MARK: Properties

    let cacheFile: NSURL

    // MARK: Initialization

    public init(url: NSURL, file: NSURL) {
        self.cacheFile = file

        super.init(operations: [])
        name = "Download Settings"

        let task = NSURLSession.sharedSession().downloadTaskWithURL(url) { url, response, error in
            self.downloadFinished(url, response: response as? NSHTTPURLResponse, error: error)
        }

        let taskOperation = URLSessionTaskOperation(task: task)

        let reachabilityCondition = ReachabilityCondition(host: url)
        taskOperation.addCondition(reachabilityCondition)

        let networkObserver = NetworkObserver()
        taskOperation.addObserver(networkObserver)

        addOperation(taskOperation)
    }

    func downloadFinished(url: NSURL?, response: NSHTTPURLResponse?, error: NSError?) {
        if let localURL = url where response != nil && response!.statusCode / 100 == 2 {
            do {
                /*
                If we already have a file at this location, just delete it.
                Also, swallow the error, because we don't really care about it.
                */
                try NSFileManager.defaultManager().removeItemAtURL(cacheFile)
            }
            catch { }

            do {
                try NSFileManager.defaultManager().moveItemAtURL(localURL, toURL: cacheFile)
            }
            catch let error as NSError {
                aggregateError(error)
            }

        }
        else if let error = error {
            aggregateError(error)
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
}

