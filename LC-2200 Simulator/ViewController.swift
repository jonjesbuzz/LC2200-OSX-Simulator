//
//  ViewController.swift
//  LC-2200 Simulator
//
//  Created by Jonathan Jemson on 2/25/16.
//  Copyright © 2016 Jonathan Jemson. All rights reserved.
//

import Cocoa
import LC2200Kit

class ViewController: NSViewController {
    
    internal var processor: LC2200Processor!

    @IBOutlet weak var memoryTableView: NSTableView!
    @IBOutlet weak var registerTableView: NSTableView!
    
    let queue = dispatch_queue_create("com.cixocommunications.LC-2200-Simulator.runQueue", DISPATCH_QUEUE_SERIAL)
    
    
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
        self.memoryTableView.selectRowIndexes(NSIndexSet(index: index), byExtendingSelection: false)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["lc", "s"]
        let result = openPanel.runModal()
        openPanel.allowsMultipleSelection = false
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        if result == NSFileHandlingPanelOKButton {
            let memory: String
            if openPanel.URLs.first!.pathExtension == "lc" {
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
            } else if openPanel.URLs.first!.pathExtension == "s" {
                do {
                    memory = try String(contentsOfURL: openPanel.URLs.first!, encoding: NSUTF8StringEncoding)
                } catch {
                    print(error)
                    exit(1)
                }
                var assembler = LC2200Assembler(source: memory)
                processor.setupMemory(assembler.assemble())
            }
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
        dispatch_async(queue) { [unowned self] in
            self.processor.run()
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func stepProcessor(sender: NSButton) {
        dispatch_async(queue) { [unowned self] in
            self.processor.step()
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func rewindProcessor(sender: NSButton) {
        dispatch_async(queue) { [unowned self] in
            self.processor.rewind()
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func resetProcessor(sender: NSButton) {
        dispatch_async(queue) { [unowned self] in
            self.processor.reset()
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func setBreakpoint(sender: NSButton) {
        dispatch_async(queue) { [unowned self] in
            self.processor.setBreakpoint(UInt16(self.memoryTableView.selectedRow))
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    @IBAction func removeBreakpoint(sender: NSButton) {
        dispatch_async(queue) { [unowned self] in
            self.processor.removeBreakpoint(UInt16(self.memoryTableView.selectedRow))
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.processorDidChange()
            }
        }
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

