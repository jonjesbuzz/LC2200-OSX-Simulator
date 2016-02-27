//
//  LC2200DataSource.swift
//  LC-2200 Simulator
//
//  Created by Jonathan Jemson on 2/25/16.
//  Copyright © 2016 Jonathan Jemson. All rights reserved.
//

import Cocoa
import LC2200Kit

extension ViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        switch tableView {
        case self.memoryTableView:
            return self.processor.memory.count
        case self.registerTableView:
            return self.processor.registers.count
        default:
            return 0
        }
    }
}

extension ViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == self.memoryTableView {
            return configureMemoryTableCell(column: tableColumn, row: row)
        } else if tableView == self.registerTableView {
            return configureRegisterTableCell(column: tableColumn, row: row)
        }
        return nil
    }
    
    private func configureMemoryTableCell(column column: NSTableColumn?, row: Int) -> NSView? {
        var text = ""
        var identifier = ""
        let memLoc = processor.memory[row]
        if column == memoryTableView.tableColumns[0] {
            text = String(format: "0x%04x", row)
            identifier = "addressCellID"
        } else if column == memoryTableView.tableColumns[1] {
            text = "\(memLoc)"
            identifier = "decimalCellID"
        } else if column == memoryTableView.tableColumns[2] {
            text = String(format: "0x%04x", memLoc)
            identifier = "hexCellID"
        } else if column == memoryTableView.tableColumns[3] {
            text = Instruction(value: memLoc).debugDescription
            identifier = "instructionCellID"
        }
        if let cell = self.memoryTableView.makeViewWithIdentifier(identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            if (processor.hasBreakpointAtAddress(UInt16(row))) {
                cell.layer?.backgroundColor = NSColor(hue: 0.0, saturation: 0.46, brightness: 0.92, alpha: 1.0).CGColor
            } else {
                cell.layer?.backgroundColor = NSColor.clearColor().CGColor
            }
            return cell
        }
        return nil
    }
    
    private func configureRegisterTableCell(column column: NSTableColumn?, row: Int) -> NSView? {
        var text = ""
        var identifier = ""
        if column == registerTableView.tableColumns[0] {
            text = RegisterFile.Register(rawValue: UInt8(truncatingBitPattern: row))!.description
            identifier = "registerCellID"
        } else if column == registerTableView.tableColumns[1] {
            text = "\(processor.registers[row])"
            if (row >= 13) {
                text = String(format: "0x%04x", processor.registers[row])
            }
            identifier = "registerValueCellID"
        }
        if let cell = self.registerTableView.makeViewWithIdentifier(identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}