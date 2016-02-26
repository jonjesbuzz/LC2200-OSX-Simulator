//
//  ViewController.swift
//  LC-2200 Simulator
//
//  Created by Jonathan Jemson on 2/25/16.
//  Copyright © 2016 Jonathan Jemson. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    internal var processor: LC2200Processor!

    @IBOutlet weak var memoryTableView: NSTableView!
    @IBOutlet weak var registerTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.processor = LC2200Processor()
        memoryTableView.setDelegate(self)
        registerTableView.setDelegate(self)
        memoryTableView.setDataSource(self)
        registerTableView.setDataSource(self)
        registerTableView.target = self
        registerTableView.doubleAction = #selector(ViewController.goToRegister)
    }
    
    func goToRegister() {
        let register = RegisterFile.Register(rawValue: UInt8(truncatingBitPattern: registerTableView.selectedRow))!
        let index = Int(processor.registers[register])
        self.memoryTableView.scrollRowToVisible(index)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["lc"]
        let result = openPanel.runModal()
        openPanel.allowsMultipleSelection = false
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        if result == NSFileHandlingPanelOKButton {
            let memory: String
            do {
                memory = try String(contentsOfURL: openPanel.URLs.first!, encoding: NSUTF8StringEncoding)
            } catch {
                print(error)
                exit(1)
            }
            let vals = memory.characters.split { $0 == " " || $0 == "\n" }.map(String.init)
            let things = vals.map { (s) -> (UInt16) in
                if let data = UInt16(s, radix: 16) {
                    return data
                }
                print("File \(openPanel.URLs.first!) is not a valid LC2200 file.")
                exit(1)
            }
            processor.setupMemory(things)
            self.memoryTableView.reloadData()
            let indexSet = NSIndexSet(index: Int(self.processor.currentAddress))
            self.memoryTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            self.memoryTableView.allowsEmptySelection = false
            self.registerTableView.reloadData()
        } else {
            exit(0)
        }
    }
    @IBAction func runProcessor(sender: NSButton) {
        processor.run()
        processorDidChange()
    }
    
    @IBAction func stepProcessor(sender: NSButton) {
        processor.step()
        processorDidChange()
    }
    
    @IBAction func rewindProcessor(sender: NSButton) {
        processor.rewind()
        processorDidChange()
    }
    
    @IBAction func resetProcessor(sender: NSButton) {
        processor.reset()
        processorDidChange()
    }
    
    private func processorDidChange() {
        let indexSet = NSIndexSet(index: Int(self.processor.currentAddress))
        self.memoryTableView.reloadData()
        self.memoryTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        self.memoryTableView.scrollRowToVisible(indexSet.firstIndex)
        self.registerTableView.reloadData()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

