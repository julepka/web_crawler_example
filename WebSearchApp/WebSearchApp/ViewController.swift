//
//  ViewController.swift
//  WebSearchApp
//
//  Created by Julia Potapenko on 13.07.2017.
//  Copyright © 2017 Julia Potapenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    // MARK: - Outlest
    
    @IBOutlet weak var searchUrlTextField: UITextField!
    @IBOutlet weak var searchTextTextField: UITextField!
    @IBOutlet weak var maxThreadNumberTextField: UITextField!
    @IBOutlet weak var maxUrlNumberTextField: UITextField!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private var dataLoader: DataLoader? = nil
    private var operationQueue: OperationQueue = OperationQueue()
    private var cellData: [Int: DataLoader.Response] = [:]
    private var urlIndexes: [String: Int] = [:]
    
    // MARK: - Actions
    
    @IBAction func startButtonAction(sender: UIButton) {
        
        // text field validation
        
        guard let searchURL = searchUrlTextField.text,
            let searchText = searchTextTextField.text,
            let maxThreadNumber = maxThreadNumberTextField.text,
            let maxUrlNumber = maxUrlNumberTextField.text else {
            return
        }
        
        guard let maxThreads = Int(maxThreadNumber), let maxUrls = Int(maxUrlNumber) else {
            showSampleInputAlertView()
            return
        }
        
        if searchURL.isEmpty || searchText.isEmpty || maxThreadNumber.isEmpty || maxUrlNumber.isEmpty || maxThreads == 0 || maxUrls == 0 {
            showSampleInputAlertView()
            return
        }
        
        // clearing all previous data
        
        self.setButtonsEnabled(start: false, pause: true, stop: true, pauseTitle: "Pause")
        
        self.cellData = [:]
        self.urlIndexes = [:]
        self.dataLoader = nil
        
        self.progressView.progress = 0
        
        // data loader and operation
        
        operationQueue.maxConcurrentOperationCount = maxThreads
        dataLoader = DataLoader(searchUrl: searchURL, searchText: searchText, maxThreadNumber: maxThreads, maxUrlNumber: maxUrls)
        
        // operation
        
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            self.dataLoader?.start() { [weak self] responce in
                if responce.loading {
                    if let index = self?.cellData.count {
                        self?.cellData[index] = responce
                        self?.urlIndexes[responce.url] = index
                    }
                } else {
                    if let index = self?.urlIndexes[responce.url] {
                        self?.cellData[index] = responce
                        if let progress = self?.progressView.progress {
                            self?.progressView.progress = progress + (1.0 / Float(maxUrls))
                        }
                    }
                }
                self?.tableView.reloadData()
            }
        }
        
        operation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.progressView.progress = 1
                self?.setButtonsEnabled(start: true, pause: false, stop: false, pauseTitle: "Pause")
                self?.tableView.reloadData()
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func showSampleInputAlertView() {
        let alertController = UIAlertController(title: "Invalid Input", message: "Please, fill out all entry fields properly or use a sample input.", preferredStyle: .alert)
        
        let autofillAlertAction = UIAlertAction(title: "Sample Input", style: .default) {
            (result : UIAlertAction) -> Void in
            self.searchUrlTextField.text = "https://habrahabr.ru/"
            self.searchTextTextField.text = "IT"
            self.maxThreadNumberTextField.text = "25"
            self.maxUrlNumberTextField.text = "100"
        }
        
        let okAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(autofillAlertAction)
        alertController.addAction(okAlertAction)
        self.show(alertController, sender: nil)
    }
    
    @IBAction func pauseButtonAction(sender: UIButton) {
        if let activeDataLoader = dataLoader {
            switch activeDataLoader.state {
            case .working:
                setButtonsEnabled(start: false, pause: true, stop: true, pauseTitle: "Resume")
                dataLoader?.pause()
            case .paused:
                setButtonsEnabled(start: false, pause: true, stop: true, pauseTitle: "Pause")
                dataLoader?.resume()
            default:
                break
            }
        }
    }
    
    @IBAction func stopButtonAction(sender: UIButton) {
        
        self.setButtonsEnabled(start: true, pause: false, stop: false, pauseTitle: "Pause")
        
        dataLoader?.stop()
        operationQueue.cancelAllOperations()
        dataLoader = nil
    }
    
    private func setButtonsEnabled(start: Bool, pause: Bool, stop: Bool, pauseTitle: String) {
        startButton.isEnabled = start
        pauseButton.isEnabled = pause
        stopButton.isEnabled = stop
        pauseButton.setTitle(pauseTitle, for: .normal)
    }
    
    // MARK: - ViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopButtonAction(sender: stopButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.stopButtonAction(sender: stopButton)
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTableViewCell", for: indexPath) as? SearchResultTableViewCell else {
            return UITableViewCell()
        }
        if let data = cellData[indexPath.row] {
            cell.titleLabel.text = data.title
            cell.urlLabel.text = data.url
            cell.resultLabel.text = "Found: \(data.found)   Error: \(data.error ?? "No error")"
        }
        return cell
    }
    
    // MARK: - TextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

}

