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
    
    let queue = DispatchQueue(label: "com.cixocommunications.LC-2200-Simulator.runQueue", attributes: [])
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.processor = LC2200Processor()
        memoryTableView.delegate = self
        registerTableView.delegate = (self)
        memoryTableView.dataSource = (self)
        registerTableView.dataSource = (self)
        registerTableView.target = self
        registerTableView.doubleAction = #selector(ViewController.goToRegister)
    }
    
    func goToRegister() {
        let register = RegisterFile.Register(rawValue: UInt8(truncatingBitPattern: registerTableView.selectedRow))!
        let index = Int(processor.registers[register])
        self.memoryTableView.scrollRowToVisible(index)
        self.memoryTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
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
            if openPanel.urls.first!.pathExtension == "lc" {
                do {
                    memory = try String(contentsOf: openPanel.urls.first!, encoding: String.Encoding.utf8)
                } catch {
                    print(error)
                    exit(1)
                }
                let vals = memory.characters.split { $0 == " " || $0 == "\n" }.map(String.init)
                let things = vals.map { (s) -> (UInt16) in
                    if let data = UInt16(s, radix: 16) {
                        return data
                    }
                    print("File \(openPanel.urls.first!) is not a valid LC2200 file.")
                    exit(1)
                }
                processor.setupMemory(things)
            } else if openPanel.urls.first!.pathExtension == "s" {
                do {
                    memory = try String(contentsOf: openPanel.urls.first!, encoding: String.Encoding.utf8)
                } catch {
                    print(error)
                    exit(1)
                }
                var assembler = LC2200Assembler(source: memory)
                do {
                    processor.setupMemory(try assembler.assemble())
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Could not parse assembly."
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    exit(1)
                }
            }
            self.memoryTableView.reloadData()
            let indexSet = IndexSet(integer: Int(self.processor.currentAddress))
            self.memoryTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            self.memoryTableView.allowsEmptySelection = false
            self.registerTableView.reloadData()
        } else {
            exit(0)
        }
    }
    @IBAction func runProcessor(_ sender: NSButton) {
        queue.async { [unowned self] in
            self.processor.run()
            DispatchQueue.main.async { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func stepProcessor(_ sender: NSButton) {
        queue.async { [unowned self] in
            self.processor.step()
            DispatchQueue.main.async { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func rewindProcessor(_ sender: NSButton) {
        queue.async { [unowned self] in
            _ = self.processor.rewind()
            DispatchQueue.main.async { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func resetProcessor(_ sender: NSButton) {
        queue.async { [unowned self] in
            self.processor.reset()
            DispatchQueue.main.async { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    @IBAction func setBreakpoint(_ sender: NSButton) {
        queue.async { [unowned self] in
            self.processor.setBreakpoint(location: UInt16(self.memoryTableView.selectedRow))
            DispatchQueue.main.async { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    @IBAction func removeBreakpoint(_ sender: NSButton) {
        queue.async { [unowned self] in
            self.processor.removeBreakpoint(location: UInt16(self.memoryTableView.selectedRow))
            DispatchQueue.main.async { [unowned self] in
                self.processorDidChange()
            }
        }
    }
    
    fileprivate func processorDidChange() {
        let indexSet = IndexSet(integer: Int(self.processor.currentAddress))
        self.memoryTableView.reloadData()
        self.memoryTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        self.memoryTableView.scrollRowToVisible(indexSet.first ?? 0)
        self.registerTableView.reloadData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

