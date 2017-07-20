//
//  DataLoader.swift
//  WebSearchApp
//
//  Created by Julia Potapenko on 13.07.2017.
//  Copyright © 2017 Julia Potapenko. All rights reserved.
//

import Foundation

class DataLoader {
    
    enum State {
        case working
        case paused
        case stopped
    }
    
    struct Response {
        var loading: Bool
        var title: String
        let url: String
        var found: Int
        var error: String?
    }
    
    private var searchUrl: String
    private var searchText: String
    private var maxThreadNumber: Int
    private var maxUrlNumber: Int
    
    private var queue: [String] = []
    private var urlSet: Set<String> = []
    var operationQueue = OperationQueue()
    var state: State = .stopped
    
    init(searchUrl: String, searchText: String, maxThreadNumber: Int, maxUrlNumber: Int) {
        self.searchUrl = searchUrl
        self.searchText = searchText
        self.maxThreadNumber = maxThreadNumber
        self.maxUrlNumber = maxUrlNumber
        self.operationQueue.maxConcurrentOperationCount = maxThreadNumber
    }
    
    func start(update: @escaping (Response) -> ()) {
        self.state = .working
        self.queue.append(searchUrl)
        self.urlSet.insert(searchUrl)
        while !queue.isEmpty && maxUrlNumber >= urlSet.count {
        
            var nextQueue: [String] = []
            for _ in queue {
                guard let currentSearchUrl = queue.first else {
                    continue
                }
                queue.removeFirst()
                
                let operation = BlockOperation()
                operation.addExecutionBlock { [weak self, weak operation] in
                    
                    // callback: started loading
                    self?.sendCallback() { _ in
                        update(Response(loading: true, title: "Loading...", url: currentSearchUrl, found: 0, error: nil))
                    }
                    
                    // sending request
                    guard let op = operation else {
                        return
                    }
                    guard let response = self?.sendRequest(op, url: currentSearchUrl) else {
                        return
                    }
                    
                    // callback: finished loading
                    self?.sendCallback() { _ in
                        let title = response.title == "" ? "No Title" : response.title
                        update(Response(loading: false, title: title, url: currentSearchUrl, found: response.found, error: response.error))
                    }
                    
                    // copying data to the next queue
                    self?.lock() {
                        if let strongSelf = self {
                            for child in response.childs {
                                if strongSelf.urlSet.count >= strongSelf.maxUrlNumber {
                                    break
                                }
                                if !strongSelf.urlSet.contains(child) {
                                    nextQueue.append(child)
                                    strongSelf.urlSet.insert(child)
                                }
                            }
                        }
                    }
                }
                
                if self.state != .stopped {
                    self.operationQueue.addOperation(operation)
                }
            }
            self.operationQueue.waitUntilAllOperationsAreFinished()
            queue = nextQueue
        }
    }
    
    func stop() {
        state = .stopped
        operationQueue.cancelAllOperations()
        queue.removeAll()
    }
    
    func pause() {
        if state == .working {
            state = .paused
            operationQueue.isSuspended = true
        }
    }
    
    func resume() {
        if state == .paused {
            state = .working
            operationQueue.isSuspended = false
        }
    }
    
    private func sendRequest(_ operation: BlockOperation, url: String) -> WebParser.Response {
        let canceledResponse = WebParser.Response(title: "Canceled", found: 0, childs: [], error: "Canceled")
        if operation.isCancelled {
            return canceledResponse
        }
        let responce = WebParser().parse(searchUrl: url, searchText: self.searchText)
        if operation.isCancelled {
            return canceledResponse
        }
        return responce
    }
    
    private func lock(_ closure: () -> ()) {
        DispatchQueue.global().sync {
            closure()
        }
    }
    
    private func sendCallback(_ closure: @escaping () -> ()) {
        DispatchQueue.main.async {
            closure()
        }
    }
    
}
