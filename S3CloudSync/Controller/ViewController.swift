//
//  ViewController.swift
//  S3CloudSync
//
//  Created by Ulrich Vormbrock on 23.10.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Cocoa



/*
 * Workflow - at startup:
 *
 * 1. Download remote JSON file -> overwrite local JSON (TODO: better we should compare timestamps)
 * 2. Map local JSON to CoreData
 * 3. Map local files (mp4, png and srt) to CoreData
 * 4. Display assets from CoreData in Table View
 *
 * Workflow - after local file changes and tapping the "reload button":
 *
 * 1. Update local JSON - with new "sha 256" values
 * 2. Map local JSON to CoreData -> local and remote "sha 256" are different
 * 3. Display assets from CoreData in Table View and mark updated assets
 * 4. Upload the updated assets
 * 5. Upload the updated JSON with the new "sha 256" values according to the uploaded assets
 *
 * Workflow - after adding new files to the local filesystem and tapping the "reload button"
 *
 * 1. Check for consistency - there must be a group of mp4, png and srt file
 * 2. Add new file group to JSON (fileName, id and sha 256 values) -> the user must add the remaining values by himself
 * 3. Map local JSON to CoreData -> local and remote "sha 256" are the same, provide a flag "onServer = false"
 * 4. Upload the updated assets
 * 5. Upload the updated JSON
 * 6. Update flag "onServer = true" in CoreData
 *
 *
 */
class ViewController: NSViewController, NSFetchedResultsControllerDelegate {
    
    lazy var fetchedResultsController: NSFetchedResultsController<Asset> = {
        
        let fetchRequest = NSFetchRequest<Asset> (entityName: Asset.className())
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "element.fileName", ascending: true), NSSortDescriptor (key: "type", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController<Asset> (
            fetchRequest: fetchRequest,
            managedObjectContext: PersistencyManager.shared.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            print("fetch error \(error)")
        }
        
        return fetchedResultsController
    }()
    
    
    @IBOutlet weak var uploadAllButton: NSButton!
    @IBOutlet weak var tableView: NSTableView!

    
    // TODO: get new files from the filesystem, add them to JSON and upload them into the cloud, too
    // Also make a table column "new file"
    // TODO: provide possibility to revert a local change: the changes are then overwritten by the original file from the cloud
    // Make a table column "revert change"
    // TODO: check also for consistency: each file group must contain a mp4, a png and a srt file
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //PersistencyManager.shared.clearDB()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        
        configureSortDescriptors()
        configureUploadAllButton()
        
        LibraryAPI.shared.mapLocalFileSystemToCoreData()
        LibraryAPI.shared.downloadJSON()
        LibraryAPI.shared.mapJSONToCoreData()
        
        updateGUI()
    }
    
    fileprivate func updateGUI() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        
        tableView.reloadData()
        enableUploadAllButton(LibraryAPI.shared.hasUpdatedAssets())
    }
    
    @IBAction func uploadAllButtonTouched(_ sender: Any) {
        
        let updatedElements = PersistencyManager.shared.getAllUpdatedElements()
        print("number of updated elements: \(updatedElements.count)")
        
        LibraryAPI.shared.uploadAllUpdatedAssets()
        
        PersistencyManager.shared.syncAllRemoteSha256 {
            JSONHelper().updateLocalJSON()
        }
        
        //LibraryAPI.shared.updateCoreData()
    }
    
    @IBAction func reloadButtonTouched(_ sender: Any) {
        //LibraryAPI.shared.updateCoreData()
        updateGUI()
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
    
    fileprivate func configureSortDescriptors() {
        let descriptorName = NSSortDescriptor(key: FileHelper.FileOrder.Name.rawValue, ascending: true)
        let descriptorDate = NSSortDescriptor(key: FileHelper.FileOrder.Size.rawValue, ascending: true)
        let descriptorSize = NSSortDescriptor(key: FileHelper.FileOrder.Date.rawValue, ascending: true)
        tableView.tableColumns[0].sortDescriptorPrototype = descriptorName
        tableView.tableColumns[1].sortDescriptorPrototype = descriptorDate
        tableView.tableColumns[2].sortDescriptorPrototype = descriptorSize
    }
    
    fileprivate func enableUploadAllButton(_ flag: Bool) {
        uploadAllButton.isEnabled = flag
        uploadAllButton.alphaValue = flag == true ? 1.0 : 0.5
    }
    
    fileprivate func configureUploadAllButton() {
        uploadAllButton.bezelStyle = .rounded
        uploadAllButton.wantsLayer = true
        uploadAllButton.layer?.backgroundColor = NSColor.green.cgColor
        uploadAllButton.layer?.cornerRadius = 5.0
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
            
            if order == FileHelper.FileOrder.Name {
                self.fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor (key: "element.fileName", ascending: !sortDescriptor.ascending), NSSortDescriptor (key: "type", ascending: true)]
            } else if  order == FileHelper.FileOrder.Size {
                self.fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor (key: "size", ascending: !sortDescriptor.ascending)]
            } else if  order == FileHelper.FileOrder.Date {
                self.fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor (key: "modDate", ascending: !sortDescriptor.ascending)]
            }
            
            updateGUI()
        }
    }
}


extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "nameCell"
        static let SizeCell = "sizeCell"
        static let DateCell = "dateCell"
        static let IsNewFileCell = "isNewFileCell"
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
            // TODO: new attribute "isNew" for asset
            text = "" //asset.hasLocalChanges ? "yes" : ""
            cellIdentifier = CellIdentifiers.IsNewFileCell
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
