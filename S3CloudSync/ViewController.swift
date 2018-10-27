//
//  ViewController.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 23.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa


class ViewController: NSViewController, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<Asset>!
    
    
    @IBOutlet weak var uploadAllButton: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
    
    let s3cmd = S3CMD()
    
    var assetsToUploadDict = [String: String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let fetchRequest = NSFetchRequest<Asset> (entityName: "Asset")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "element.fileName", ascending: true), NSSortDescriptor (key: "type", ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController<Asset> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        
        let descriptorName = NSSortDescriptor(key: FileHelper.FileOrder.Name.rawValue, ascending: true)
        let descriptorDate = NSSortDescriptor(key: FileHelper.FileOrder.Size.rawValue, ascending: true)
        let descriptorSize = NSSortDescriptor(key: FileHelper.FileOrder.Date.rawValue, ascending: true)
        
        tableView.tableColumns[0].sortDescriptorPrototype = descriptorName
        tableView.tableColumns[1].sortDescriptorPrototype = descriptorDate
        tableView.tableColumns[2].sortDescriptorPrototype = descriptorSize
        
        uploadAllButton.bezelStyle = .rounded
        uploadAllButton.wantsLayer = true
        uploadAllButton.layer?.backgroundColor = NSColor.green.cgColor
        uploadAllButton.layer?.cornerRadius = 5.0
        
        syncFileSystems()
        
        //s3cmd.uploadAllLocalAssets()
    }
    
    fileprivate func enableUploadAllButton(_ flag: Bool) {
        uploadAllButton.isEnabled = flag
        uploadAllButton.alphaValue = flag == true ? 1.0 : 0.5
    }
    
    fileprivate func syncFileSystems() {
        //CoreDataManager.sharedInstance.clearDB()
        
        // TODO: perfom initial upload from JSON with inital sha256 values from locale filesystem -> maybe generate JSON automatically
        
        // get actual JSON from Cloud
        s3cmd.downloadRemoteJSON(to: Constants.localFilepath)
        
        JSONHelper().mapJSONToCoreData {
            FileHelper().mapLocalFilesToCoreData()
        }
        
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("An error occurred")
        }
        
        let updatedElements = CoreDataManager.sharedInstance.getAllUpdatedElements()
        enableUploadAllButton(updatedElements.count > 0)
    }
    
    @IBAction func uploadAllButtonTouched(_ sender: Any) {
        
        let updatedElements = CoreDataManager.sharedInstance.getAllUpdatedElements()
        print("number of updated elements: \(updatedElements.count)")
        
        for element in updatedElements {
           s3cmd.uploadLocalAsset(element)
        }
        
        CoreDataManager.sharedInstance.syncAllRemoteSha256 {
            JSONHelper().updateLocalAndRemoteJSON()
        }
        
        syncFileSystems()

    }
    
    @IBAction func reloadButtonTouched(_ sender: Any) {
        do {
            FileHelper().mapLocalFilesToCoreData()
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("An error occurred")
        }
        
        let updatedElements = CoreDataManager.sharedInstance.getAllUpdatedElements()
        enableUploadAllButton(updatedElements.count > 0)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {

        let asset = self.fetchedResultsController.object(at: IndexPath(item: tableView.selectedRow, section: 0))
        let url = URL(fileURLWithPath: asset.localeFilePath!)
        NSWorkspace.shared.open(url)
    }
    
}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (fetchedResultsController.fetchedObjects?.count)!
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        
        if let order = FileHelper.FileOrder(rawValue: sortDescriptor.key!) {

            do {
                
                if order == FileHelper.FileOrder.Name {
                    self.fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor (key: "element.fileName", ascending: !sortDescriptor.ascending), NSSortDescriptor (key: "type", ascending: true)]
                } else if  order == FileHelper.FileOrder.Size {
                    self.fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor (key: "size", ascending: !sortDescriptor.ascending)]
                } else if  order == FileHelper.FileOrder.Date {
                    self.fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor (key: "modDate", ascending: !sortDescriptor.ascending)]
                }

                //FileHelper().mapLocalFilesToCoreData() // get local changes
                try fetchedResultsController.performFetch()
                tableView.reloadData()
            } catch {
                print("An error occurred")
            }
        }
    }
    
}


extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "nameCell"
        static let SizeCell = "sizeCell"
        static let DateCell = "dateCell"
        static let HasChangesCell = "hasChangesCell"
        static let SingleUploadCell = "singleUploadCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd - HH:mm"
        
        let asset = self.fetchedResultsController.object(at: IndexPath(item: row, section: 0))

        if tableColumn == tableView.tableColumns[0] {
            
            if asset.type == 1 {
                image = NSImage(named: "mp4")
            } else if asset.type == 2 {
                image = NSImage(named: "png")
            } else if asset.type == 3 {
                image = NSImage(named: "doc")
            }
            
            text = (asset.localeFilePath?.components(separatedBy: "/").last)!
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = ByteCountFormatter().string(fromByteCount: asset.size)
            cellIdentifier = CellIdentifiers.SizeCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = dateFormatter.string(from: asset.modDate! as Date)
            cellIdentifier = CellIdentifiers.DateCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = asset.hasLocalChanges ? "yes" : ""
            cellIdentifier = CellIdentifiers.HasChangesCell
        } else if tableColumn == tableView.tableColumns[4] {
            text = ""
            cellIdentifier = CellIdentifiers.SingleUploadCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            
            if cellIdentifier == CellIdentifiers.SingleUploadCell {
                
                if asset.hasLocalChanges {
                    cell.wantsLayer = true
                    cell.layer?.masksToBounds = true
                    cell.layer?.cornerRadius = 5.0
                    cell.layer?.backgroundColor = NSColor.green.cgColor
                    text = "upload"
                } else {
                    cell.wantsLayer = false
                    cell.layer?.masksToBounds = false
                    cell.layer?.cornerRadius = 0.0
                    cell.layer?.backgroundColor = NSColor.clear.cgColor
                    text = ""
                }
           
            }
            
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        //updateStatus()
    }
}
