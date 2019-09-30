//
//  SourceEditorCommand.swift
//  XCSmartCutCopyPasteExtension
//
//  Created by Mike Retondo on 8/16/18.
//  Copyright © 2018 Mike Retondo. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

enum Options: String {
    case Cut, Copy, Paste
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    static var pasteboardItemCopiedInLineMode: String? = nil
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        let commandIdentifierRawValue = invocation.commandIdentifier.components(separatedBy: ".").last!
        let buffer = invocation.buffer
        let lines = buffer.lines
        let selections = buffer.selections as! [XCSourceTextRange]
        let firstObject = buffer.selections.firstObject as? XCSourceTextRange
        let lastObject = buffer.selections.lastObject as? XCSourceTextRange
        
        for selection in selections {
            if commandIdentifierRawValue == Options.Paste.rawValue {
                // alow pasting beyond last line i.e. virtual last line
                guard selection.start.line <= lines.count else { completionHandler(nil); return }
                guard (firstObject != nil), (firstObject?.start.line)! <= lines.count else { completionHandler(nil); return }
            } else {
                // no selection can start beyond last line
                guard selection.start.line < lines.count else { completionHandler(nil); return }
                guard (firstObject != nil), (firstObject?.start.line)! < lines.count else { completionHandler(nil); return }
            }
        }
        
        // insertion point is the empty selection or last selection
        var insertionPoint = XCSourceTextPosition(line: lastObject!.start.line, column: lastObject!.start.column)
        
        // can't have empty selection if there are multiple selections
        let isEmptySelection = selections.count == 1 ? firstObject!.isEmptySelection() : false
        
        // line containing the insertion point is selected as if it was in line mode but NOT if pasting
        if isEmptySelection && commandIdentifierRawValue != Options.Paste.rawValue {
            firstObject!.end.line += 1
            firstObject!.start.column = 0
            firstObject!.end.column = 0
        }
        
        // insertion point line needs to adjusted upward as lines are deleted above it
        // insertion point column needs to adjusted left as columns deleted before it
        let deletedLines = linesDeletedAboveInsertionPoint(insertionPoint, selections)
        let deletedColumns = charsDeletedBefore(insertionPoint, selections)
        insertionPoint.line -= deletedLines
        insertionPoint.column -= deletedColumns
        
        /// Switch all different commands id based which defined in Info.plist
        switch Options(command: invocation.commandIdentifier)! {
        case .Cut:
            cutSelectedText(at: selections, in: buffer)
            
            let (newLine, newColumn) = insertionPointPosition(from: insertionPoint, in: buffer)
            resetSelectionTo(line: newLine, column: newColumn, in: buffer)
        case .Copy:
            copySelectedText(at: selections, in: buffer)
            
            // If no selection (Insertion Point) then copySelectedText(...) will select the line in
            // order to copy it's contents. In that case, reset the selection back to an Insertion Point.
            if isEmptySelection {
                resetSelectionTo(line: insertionPoint.line, column: insertionPoint.column, in: buffer)
            }
        case .Paste:
            pasteClipboardAt(line: insertionPoint.line, column: insertionPoint.column, in: buffer)
        }
        
        completionHandler(nil)
    }
}

extension XCSourceTextPosition: Equatable {
    public static func == (lhs: XCSourceTextPosition, rhs: XCSourceTextPosition) -> Bool {
        return lhs.line == rhs.line && lhs.column == rhs.column
    }
}

extension XCSourceTextRange {
    //
    // there's an empty selection if start equals end i.e. insertion point
    //
    func isEmptySelection() -> Bool {
        return start == end
    }
}

extension SourceEditorCommand {
    
    fileprivate func linesDeletedAboveInsertionPoint(_ insertionPointPosition: XCSourceTextPosition, _ selections: [XCSourceTextRange]) -> Int {
        var deletedLines = 0
        
        for selection in selections {
            if isSelectionInLineMode(selection) {
                for line in selection.start.line ..< selection.end.line {
                    if line < insertionPointPosition.line {
                        deletedLines += 1
                    }
                }
            }
        }
        
        return deletedLines
    }
    
    fileprivate func charsDeletedBefore(_ insertionPointPosition: XCSourceTextPosition, _ selections: [XCSourceTextRange]) -> Int {
        var deletedColumns = 0
        
        for selection in selections {
            let startLine = selection.start.line
            let startColumn = selection.start.column
            let endLine = selection.end.line
            let endColumn = selection.end.column
            
            if startLine == endLine && startLine == insertionPointPosition.line {
                if startColumn < insertionPointPosition.column  {
                    deletedColumns += (endColumn - startColumn)
                }
            }
        }
        
        return deletedColumns
    }
    
    fileprivate func areAllSelectionsInLineMode(_ selections: [XCSourceTextRange]) -> Bool {
        var isLineSelectionMode = true
        
        for selection in selections {
            if !isSelectionInLineMode(selection) {
                isLineSelectionMode = false
                break
            }
        }
        
        return isLineSelectionMode
    }
    
    fileprivate func isSelectionInLineMode(_ selection: XCSourceTextRange) -> Bool {
        return (selection.end.line > selection.start.line && selection.start.column == 0 && selection.end.column == 0)
    }
    
    fileprivate func buildStringForClipboard(from selections: [XCSourceTextRange], in buffer: XCSourceTextBuffer) -> String {
        var text = ""
        var firstPass = true
        
        // Xcode separates each selection with a newline so we do as well
        selections.forEach() { range in
            if firstPass {
                firstPass = false
            } else {
                text.append("\n")
            }
            
            text.append( textForClipboard(at: range, in: buffer) )
        }
        
        return text
    }
    
    // copy all the text selections to the clipboard and save it to compare durring a paste
    fileprivate func copySelectedTextToClipboard(at selections: [XCSourceTextRange], in buffer: XCSourceTextBuffer) {
        // put string on clipboard
        let text = buildStringForClipboard(from: selections, in: buffer)
        
        if writeTextToClipboard(text) {
            if areAllSelectionsInLineMode(selections) {
                SourceEditorCommand.pasteboardItemCopiedInLineMode = text
            } else {
                SourceEditorCommand.pasteboardItemCopiedInLineMode = nil
            }
        }
    }
    
    // put string on clipboard
    fileprivate func writeTextToClipboard(_ text: String?) -> Bool
    {
        if let text = text {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            return pasteboard.setString(text, forType: .string)
        }
        
        return false
    }
    
    // get string from clipboard
    fileprivate func readTextFromClipboard() -> String?
    {
        return NSPasteboard.general.pasteboardItems?.first?.string(forType: .string)
    }
    
    /// Gets all the lines in the buffer within a range.
    ///
    /// - Parameters:
    ///   - buffer: XCSourceTextBuffer
    ///   - range: XCSourceTextRange
    /// - Returns: [(offset: Int, element: Any)] where offset=line number and element=line's text.
    fileprivate func linesAt(_ range: XCSourceTextRange, in buffer: XCSourceTextBuffer) -> [(offset: Int, element: Any)] {
        //
        // keep each line of text that's within the range but
        // don't include last line if its' end column equals 0
        //
        // offset - line number
        // element - text of line
        //
        return buffer.lines.enumerated().filter { (offset, element) -> Bool in
            var keepLine = false
            
            // don't include last line if the column is 0
            if offset >= range.start.line {
                if offset < range.end.line {
                    keepLine = true
                } else if offset == range.end.line, range.end.column > 0 {
                    keepLine = true
                }
            }
            
            return keepLine
        }
    }
    
    /// Concatiates all the text selections seperated by a newline. If a
    /// selection ends with a newline another newline will still be appended.
    /// This is the format Xcode uses too put text onto the Clipboard when
    /// there's multiple selections.
    ///
    /// - Parameters:
    ///   - buffer: XCSourceTextBuffer
    ///   - range: XCSourceTextRange
    /// - Returns: Concatiated string of all the selections seperated by a newline
    fileprivate func textForClipboard(at range: XCSourceTextRange, in buffer: XCSourceTextBuffer) -> String {
        let lastLineNumberOfBuffer = buffer.lines.count - 1
        
        let linesWithSelections = linesAt(range, in: buffer)
        
        let concatiatedText = linesWithSelections.enumerated().reduce("") { initialResult, enumerator in
            var result = initialResult
            let lineNumber = enumerator.element.offset
            let lineText = enumerator.element.element as! String
            
            if lineNumber == range.start.line { // is the line the first within range
                if lineNumber < lastLineNumberOfBuffer { // start line is NOT last line of the buffer
                    let startIndex = lineText.index(lineText.startIndex, offsetBy: range.start.column)
                    var endIndex = lineText.endIndex
                    if lineNumber == range.end.line { // [start, end] lines are same
                        endIndex = lineText.index(lineText.startIndex, offsetBy: range.end.column)
                    }
                    result = initialResult + lineText[startIndex..<endIndex]
                } else { // start line is last line of buffer
                    let startIndex = lineText.index(lineText.startIndex, offsetBy: range.start.column)
                    let endIndex: String.Index
                    if range.end.line == range.start.line + 1 && range.end.column == 0 { // newline character is selected on last line
                        endIndex = lineText.endIndex // include newline
                    } else {
                        endIndex = lineText.index(lineText.startIndex, offsetBy: range.end.column) // don't include newline
                    }
                    result = initialResult + lineText[startIndex..<endIndex]
                }
            } else if lineNumber == range.end.line && range.end.column > 0 { // last line within range and it contains at lease 1 character
                let endIndex = lineText.index(lineText.startIndex, offsetBy: range.end.column)
                result = initialResult + lineText[..<endIndex]
            } else {
                result = initialResult + lineText // copy entire line
            }
            
            return result
        }
        
        return concatiatedText
    }
    
    fileprivate func cutSelectedText(at selections: [XCSourceTextRange], in buffer: XCSourceTextBuffer) {
        // copy the selected text in the buffer to the clipboard
        copySelectedTextToClipboard(at: selections, in: buffer)
        
        removeSelectedText(at: selections, in: buffer)
    }
    
    // transform an XCSourceTextRange to a String range
    fileprivate func rangeFromSourceTextRange(_ range: XCSourceTextRange, in buffer: XCSourceTextBuffer) -> Range<String.Index> {
        var startIndex = buffer.completeBuffer.startIndex
        var endIndex = buffer.completeBuffer.endIndex
        let lines: [String] = buffer.lines as! [String]
        
        // loop over each line of text looking for the beginning and end of a text selection
        for lineNumber in 0..<lines.count {
            var startIndexOfcurrentLine = startIndex
            var lineText = lines[lineNumber]
            if lineNumber == range.start.line {
                startIndex = buffer.completeBuffer.index(startIndex, offsetBy: range.start.column)
                let endLineNumber = range.end.line == lines.count ? range.end.line - 1 : range.end.line
                
                for lineNum in lineNumber...endLineNumber {
                    lineText = lines[lineNum]
                    if lineNum == endLineNumber {
                        // we are at the last line of buffer
                        if lineNum == lines.count - 1 && range.end.column == 0 {
                            // the entire line of text including the newline
                            endIndex = buffer.completeBuffer.index(startIndexOfcurrentLine, offsetBy: lineText.count)
                        } else {
                            // only the text up to the column position
                            endIndex = buffer.completeBuffer.index(startIndexOfcurrentLine, offsetBy: range.end.column)
                        }
                        break;
                    } else {
                        startIndexOfcurrentLine = buffer.completeBuffer.index(startIndexOfcurrentLine, offsetBy: lineText.count)
                    }
                }
                
                break;
            } else {
                startIndex = buffer.completeBuffer.index(startIndex, offsetBy: lineText.count)
            }
        }
        
        return startIndex ..< endIndex
    }
    
    fileprivate func getCharsOnLastLine(_ text: String, _ linesInserted: Int, _ newlineIndices: [String.Index]) -> Int {
        var columnsInserted = 0
        
        if linesInserted > 0 {
            let lastNewlineCharIndex = text.index(after: newlineIndices[linesInserted - 1])
            columnsInserted = text[lastNewlineCharIndex ..< text.endIndex].count
        } else {
            columnsInserted = text.count
        }
        
        return columnsInserted
    }
    
    fileprivate func pasteClipboardAt(line: Int, column: Int, in buffer: XCSourceTextBuffer) {
        if let clipboardText = readTextFromClipboard() {
            //
            // when pasting we need to first remove all the current selections
            // then remove all the selections from the lines array
            //
            let selections = buffer.selections as! [XCSourceTextRange]
            removeSelectedText(at: selections, in: buffer)
            
            // adjust line/column position in case they no longer exist
            var insertionPoint = XCSourceTextPosition(line: line, column: column)
            let (line, column) = insertionPointPosition(from: insertionPoint, in: buffer)
            
            // how many lines are inserted
            // how many columns are inserted on the last line
            let newlineIndices: [String.Index] = clipboardText.indices(of: "\n")
            let linesInserted = newlineIndices.count
            let columnsInserted = getCharsOnLastLine(clipboardText, linesInserted, newlineIndices)
            
            //
            // if pasteboard equals the last Cut or Copy, paste it in line mode
            //
            if clipboardText == SourceEditorCommand.pasteboardItemCopiedInLineMode {
                // insert line(s) of text
                buffer.lines.insert(clipboardText, at: line)
                
                // move insertion point to last line of inserted text
                insertionPoint = XCSourceTextPosition(line: line + linesInserted, column: column)
            } else if line >= buffer.lines.count {
                // insert line(s) of text starting at the virtual line below the last line
                buffer.lines.insert(clipboardText, at: line)
                
                // move insertion point to the end of inserted text
                insertionPoint = XCSourceTextPosition(line: line + linesInserted, column: columnsInserted)
            } else {
                // Combine first and last lines into one
                let lines = String((buffer.lines[line] as! String).prefix(column)) +
                            clipboardText +
                            String((buffer.lines[line] as! String)[column...])

                // replace the line with one or more lines
                buffer.lines.removeObject(at: line)
                buffer.lines.insert(lines, at: line)
                
                // move insertion point to last line/column of inserted text
                if linesInserted > 0 {
                    insertionPoint = XCSourceTextPosition(line: line + linesInserted, column: columnsInserted)
                } else {
                    insertionPoint = XCSourceTextPosition(line: line, column: column + columnsInserted)
                }
            }
            
            let (newLine, newColumn) = insertionPointPosition(from: insertionPoint, in: buffer)
            resetSelectionTo(line: newLine, column: newColumn, in: buffer)
        }
    }
    
    // delete all the selected text from the buffer
    fileprivate func removeSelectedText(at selections: [XCSourceTextRange], in buffer: XCSourceTextBuffer) {
        // delete selected text from the bottom up to keep indexes valid
        for selection in selections.reversed() {
            var linesToDelete: NSRange
            let startLine   = selection.start.line
            let endLine     = selection.end.line
            let startColumn = selection.start.column
            let endColumn   = selection.end.column
            
            if startLine < endLine {
                var replacements: [String] = []
                
                // default to line selection mode
                linesToDelete = NSMakeRange(startLine, endLine - startLine)
                
                if !areAllSelectionsInLineMode(buffer.selections as! [XCSourceTextRange]) {
                    // Lines between first and last are being deleted
                    // Combine first and last lines into one
                    let firstLine = String((buffer.lines[startLine] as! String).prefix(startColumn))
                    var lastLine = ""
                    
                    if endColumn > 0 {
                        lastLine = String((buffer.lines[endLine] as! String)[endColumn...])
                        linesToDelete = NSMakeRange(startLine, endLine - startLine + 1)
                    }
                    
                    replacements.append(firstLine + lastLine)
                }
                
                buffer.lines.replaceObjects(in: linesToDelete, withObjectsFrom: replacements)
            } else if endLine < buffer.lines.count {
                // remove text from within a single line
                var newLine = buffer.lines[endLine] as! String
                newLine.remove(from: startColumn, maxLength: endColumn - startColumn)
                
                buffer.lines[endLine] = newLine
            }
        }
    }
    
    fileprivate func copySelectedText(at selections: [XCSourceTextRange], in buffer: XCSourceTextBuffer) {
        // first save the current selection
        copySelectedTextToClipboard(at: selections, in: buffer)
    }
    
    // insertion point should be old location unless line or column doesn't exist
    fileprivate func insertionPointPosition(from oldPosition: XCSourceTextPosition, in buffer: XCSourceTextBuffer) -> (line: Int, column: Int) {
        // put insertion point back to previous line but make sure line still exists
        var line = oldPosition.line
        if line > buffer.lines.count {
            line = buffer.lines.count
            if line < 0 {
                line = 0
            }
        }
        
        // put insertion point back to previous column but make sure column still exists
        var column = oldPosition.column
        if line == buffer.lines.count {
            // always the zero column is insertion point is past the last line i.e. vertual line
            column = 0
        } else {
            let lineText = buffer.lines[line] as! String
            if column >= lineText.count {
                column = lineText.count - 1
                if column < 0 {
                    column = 0
                }
            }
        }
        
        return (line, column)
    }
    
    /// - parameter line:   line to reset selection too
    /// - parameter buffer: buffer containing the Insertion Point
    fileprivate func resetSelectionTo(line: Int, column: Int, in buffer: XCSourceTextBuffer) {
        buffer.selections.removeAllObjects()
        let position = XCSourceTextPosition(line: line, column: column)
        let selection = XCSourceTextRange(start: position, end: position)
        buffer.selections.add(selection)
    }
}
