//
//  StringUtil.swift
//
//  Created by Mike Retondo on 7/20/18.
//  Copyright © 2018 Mike Retondo. All rights reserved.
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import XcodeKit

//
// A String extension with methods like Basic has (left, mid, right)
//
extension String {
    
    func length() -> Int {
        // NSString length is equal to the number of UTF-16 code units
        return (self as NSString).length
    }
    
    func byteCount() -> Int {
        return self.utf8.count
    }
    
    func sizeInBytesUTF16() -> Int {
        // NSString length is equal to the number of UTF-16 code units which are 2 bytes each
        return self.length() * 2
    }
    
    func lineOneSpaceAt(pin: Int) -> (Int, String) {
        
        var start = pin
        while start > 0 && self[start - 1] == " " {
            start -= 1
        }
        
        var end = pin
        while end < self.count && self[end] == " " {
            end += 1
        }
        
        var newString = self
        if start == end {//No space
            newString.replaceSubrange(self.indexAt(offset: start)..<self.indexAt(offset: start), with: " ")
        } else if end - start == 1 {//If one space
            let range = self.indexAt(offset: start)..<self.indexAt(offset: end)
            newString.replaceSubrange(range, with: " ")
        } else { //More than one space
            let range = self.indexAt(offset: start)..<self.indexAt(offset: end)
            newString.replaceSubrange(range, with: " ")
        }
        return (start, newString)
    }
    
    func selectWord(pin: Int) -> Range<Index>? {
        guard let range:Range<Int> = selectWord(pin: pin) else { return nil }
        return self.indexRangeFor(range: range)
    }
    
    func selectWord(pin: Int) -> Range<Int>? {
        var pin = pin
        
        guard pin <= self.count else { return nil }
        guard self.count > 1  else { return nil }
        
        // Move pin to one position left when it is after last character
        let invalidLastChars = CharacterSet(charactersIn: " :!?,.")
        var validChars = CharacterSet.alphanumerics
        validChars.insert(charactersIn: "@_")
        
        if (pin > 0), let _ = (String(self[pin])).rangeOfCharacter(from: invalidLastChars) {
            if let _ = (String(self[pin - 1])).rangeOfCharacter(from: validChars) {
                pin -= 1
            }
        }
        
        var start = pin
        while start >= 0 && (String(self[start])).rangeOfCharacter(from: validChars) != nil {
            start -= 1
        }
        
        var end = pin
        while end < count && (String(self[end])).rangeOfCharacter(from: validChars) != nil {
            end += 1
        }
        if start == end { return nil }
        return start + 1..<end
    }

    /// All multiple whitespaces are replaced by one whitespace
    var condensedWhitespace: String {
        let components = self.components(separatedBy: .whitespaces)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    func indexAt(offset: Int) -> Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
    
    func indexRangeFor(range: Range<Int>) -> Range<Index> {
        return indexAt(offset: range.lowerBound)..<indexAt(offset: range.upperBound)
    }

    func indexRangeFor(range: ClosedRange<Int>) -> ClosedRange<Index> {
        return indexAt(offset: range.lowerBound)...indexAt(offset: range.upperBound)
    }
    
    func trimmedStart() -> String {
        return self.replacingOccurrences(of: "^[ \t]+",
                                         with: "",
                                         options: CompareOptions.regularExpression)
    }
    
    func trimmedEnd() -> String {
        return self.replacingOccurrences(of: "[ \t]+$",
                                         with: "",
                                         options: CompareOptions.regularExpression)
    }
    
    func repeating(count: Int) -> String {
        return Array<String>(repeating: self, count: count).joined()
    }
    
    func replacedRegex(pattern: String, with template: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSMakeRange(0, count)
        let modString = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
        return modString
    }

    func removingOccurrences(of occurrence: String) -> String {
        return self.replacingOccurrences(of: occurrence, with: "")
    }
    
    func substring(with range: Range<Int>) -> Substring? {
        let indices = self.indices
        
        guard range.lowerBound >= 0 && range.lowerBound < indices.count && range.upperBound <= indices.count else { return nil }
        
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        
        return self[start..<end]
    }
    
    func substring(from index: Int) -> Substring? {
        guard abs(index) < self.count else { return nil }
        
        let fromIndex = index > 0 ? self.index(self.startIndex, offsetBy: index) : self.index(self.endIndex, offsetBy: index)
        
        return self[fromIndex..<self.endIndex]
    }
    
    func substring(to index: Int) -> Substring? {
        guard abs(index) < self.count else { return nil }
        
        let fromIndex = index > 0 ? self.startIndex : self.endIndex
        let toIndex   = index > 0 ? self.index(self.startIndex, offsetBy: index) : self.index(self.endIndex, offsetBy: index)
        
        return self[fromIndex..<toIndex]
    }
    
    // [i]
    subscript(i: Int) -> Character {
        let index = self.index(self.startIndex, offsetBy: i)
        return self[index]
    }
    
    // [i..<j]
    subscript(range: Range<Int>) -> Substring {
        let i = self.index(self.startIndex, offsetBy: range.lowerBound)
        let j = self.index(self.startIndex, offsetBy: range.upperBound)
        return self[i..<j]
    }
    
    // [i...j]
    subscript(range: ClosedRange<Int>) -> Substring {
        let i = self.index(self.startIndex, offsetBy: range.lowerBound)
        let j = self.index(self.startIndex, offsetBy: range.upperBound)
        return self[i...j]
    }
    
    // [..<i]
    subscript(range: PartialRangeUpTo<Int>) -> Substring {
        let i = self.index(self.startIndex, offsetBy: range.upperBound)
        return self[..<i]
    }
    
    // [...i]
    subscript(range: PartialRangeThrough<Int>) -> Substring {
        let i = self.index(self.startIndex, offsetBy: range.upperBound)
        return self[...i]
    }
    
    // [i...]
    subscript(range: PartialRangeFrom<Int>) -> Substring {
        let i = self.index(self.startIndex, offsetBy: range.lowerBound)
        return self[i...]
    }
    
    /// Replaces the text within the specified bounds starting at 'position'
    /// and a length of 'maxLength with the given string.
    ///
    /// Calling this method invalidates any existing indices for use with this string.
    ///
    /// - Parameters:
    ///   - position: The starting charecter position in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - maxLength: The maximum number of elements to modifiy. `maxLength`
    ///     must be greater than or equal to zero.
    ///   - newString: The new String to add to the string.
    mutating func replace(from position: Int, maxLength: Int, with newString: String) {
        // if 'position' is beyond the end then set 'start' to 'endIndex'
        let start = index(startIndex, offsetBy: numericCast(position), limitedBy: endIndex) ?? endIndex
        
        // if 'start' + 'maxLength' is beyond the end then set end to 'endIndex'
        let end = index(start, offsetBy: numericCast(maxLength), limitedBy: endIndex) ?? endIndex
        
        replaceSubrange(start..<end, with: newString)
    }
    
    /// Removes the text within the specified bounds starting at 'position'
    /// and a length of 'maxLength.
    ///
    /// Calling this method invalidates any existing indices for use with this string.
    ///
    /// - Parameters:
    ///   - position: The starting charecter position in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - maxLength: The maximum number of elements to return. `maxLength`
    ///     must be greater than or equal to zero. If `maxLength` is not used
    ///     then `maxLength` is set to the remaining elements from `start`.
    mutating func remove(from position: Int, maxLength: Int = Int.max) {
        // if 'position' is beyond the end then set 'start' to 'endIndex'
        let start = index(startIndex, offsetBy: numericCast(position), limitedBy: endIndex) ?? endIndex
        
        // if 'start' + 'maxLength' is beyond the end then set end to 'endIndex'
        let end = index(start, offsetBy: numericCast(maxLength), limitedBy: endIndex) ?? endIndex
        
        removeSubrange(start..<end)
    }
    
    /// Companion function to String.prefix() and String.suffix(). It is similar to
    /// Basic's Mid() fuction.
    ///
    /// Returns a subsequence, starting from position up to the specified
    /// maximum length, containing the middle elements of the collection.
    ///
    /// If the maximum length exceeds the remaing number of elements in the
    /// collection, the result contains all the remaining elements in the collection.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.infix(from: 2, maxLength: 2))
    ///     // Prints "[3, 4]"
    ///     print(numbers.prefix(from: 2, maxLength: 10))
    ///     // Prints "[3, 4, 5]"
    ///     print(numbers.prefix(from: 10, maxLength: 2))
    ///     // Prints ""
    ///     print(numbers.infix(from: 0))
    ///     // Prints "[1, 2, 3, 4, 5]"
    ///     print(numbers.infix(from: 2))
    ///     // Prints "[3, 4, 5]"
    ///     print(numbers.infix(from: 10))
    ///     // Prints ""
    ///
    /// - Parameters:
    ///   - position: The starting charecter position in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - maxLength: The maximum number of elements to return. `maxLength`
    ///     must be greater than or equal to zero. The default for `maxLength`
    ///     is set so the remaining elements of the collection will be returned.
    /// - Returns: A subsequence starting from `position` up to `maxLength`
    ///   elements in the collection.
    func infix(from position: Int, maxLength: Int = Int.max) -> Substring {
        // if 'position' is beyond the last charecter position then set 'start' to 'endIndex'
        let start = index(startIndex, offsetBy: numericCast(position), limitedBy: endIndex) ?? endIndex
        
        // if 'start' + 'maxLength' is beyond the last charecter position then set end to 'endIndex'
        let end = index(start, offsetBy: numericCast(maxLength), limitedBy: endIndex) ?? endIndex
        
        return self[start..<end]
    }
    
    /// Returns a subsequence, starting from position and containing the elements
    /// until `predicate` returns `false` and skipping the remaining elements.
    ///
    /// - Parameters:
    ///   - position: The starting index in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - predicate: A closure that takes an element of the sequence as its
    ///     argument and returns `true` if the element should be included or
    ///     `false` if it should be excluded. Once the predicate
    ///   returns `false` it will not be called again.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    func infix(from position: Int, while predicate: (Element) throws -> Bool) rethrows -> Substring {
        // if 'position' is beyond the last charecter position then set 'start' to 'endIndex'
        let start = index(startIndex, offsetBy: numericCast(position), limitedBy: endIndex) ?? endIndex
        
        var end = start
        while try end != endIndex && predicate(self[end]) {
            formIndex(after: &end)
        }
        
        return self[start..<end]
    }
    
    /// This is similar to Basic's Left() fuction.
    ///
    /// Returns a subsequence, of the first maximum length elements of the
    /// collection. If the maximum length exceeds count nil is returned.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.left(2))
    ///     // Prints "[1, 2]"
    ///     print(numbers.left(10))
    ///     // Prints nil
    ///
    /// - Parameters:
    ///   - maxLength: The maximum number of elements to return. `maxLength`
    ///     must be greater than or equal to zero and less than or equal to count.
    /// - Returns: An optional Substring of `maxLength` elements starting from the left.
    func left(_ maxLength: Int) -> Substring? {
        
        guard maxLength >= 0 && maxLength <= count else { return nil }
        return prefix(maxLength)
    }
    
    /// This is similar to Basic's Mid() fuction.
    ///
    /// Returns a subsequence, up to the specified maximum length, containing
    /// the middle elements of the collection. If the start plus the maximum
    /// length exceeds past the end of the collection, the result is nil.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.mid(start: 2, maxLength: 2))
    ///     // Prints "[3, 4]"
    ///     print(numbers.mid(start: 2, maxLength: 10))
    ///     // Prints nil
    ///     print(numbers.mid(start: 2))
    ///     // Prints "[3, 4, 5]"
    ///
    /// - Parameters:
    ///   - start: The starting charecter position. `start` must be greater than
    ///     or equal to zero and less than or equal to count.
    ///   - maxLength: The maximum number of elements to return. `maxLength`
    ///     must be greater than or equal to zero. If `maxLength` is not used
    ///     then `maxLength` is set to the remaining elements from `start`.
    /// - Returns: An optional Substring of `maxLength` elements starting at
    ///   `start` in the collection with at most `maxLength` elements.
    func mid(startAt start: Int, maxLength: Int? = nil) -> Substring? {
        guard start >= 0 && start <= count else { return nil }
        
        if let maxLength = maxLength {
            guard maxLength >= 0 else { return nil }
            // check that `start` + `maxLength` isn't greater than Int.max by
            // checking for overflow (`end` will be negetive if overflow)
            let end = start &+ maxLength
            guard end >= 0 && end <= count else { return nil }
            
            return infix(from: start, maxLength: maxLength)
        } else {
            // all elements from start to end of container
            return infix(from: start)
        }
    }
        
    /// This is similar to Basic's Right() fuction.
    ///
    /// Returns a subsequence, of the last maximum length elements of the
    /// collection. If the maximum length exceeds count nil is returned.
    ///
    ///     let numbers = [1, 2, 3, 4, 5]
    ///     print(numbers.right(2))
    ///     // Prints "[4, 5]"
    ///     print(numbers.right(10))
    ///     // Prints nil
    ///
    /// - Parameters:
    ///   - maxLength: The maximum number of elements to return. `maxLength`
    ///     must be greater than or equal to zero and less than or equal to count.
    /// - Returns: An optional Substring of `maxLength` elements starting at from the right.
    func right(_ maxLength: Int) -> Substring? {
        guard maxLength >= 0 && maxLength <= count else { return nil }
        
        return suffix(maxLength)
    }
    
    func substringRangeFrom(range: XCSourceTextRange, lines: [String]) -> Range<String.Index> {
        var startIndex = self.startIndex
        var endIndex = startIndex
        
        // loop over each line of text looking for the beginning and end of a text selection
        for lineNumber in 0..<lines.count {
            var startIndexOfcurrentLine = startIndex
            var lineText = lines[lineNumber]
            if (lineNumber == range.start.line) {
                startIndex = self.index(startIndex, offsetBy: range.start.column)
                let endLineNumber = range.end.line == lines.count ? range.end.line - 1 : range.end.line
                
                for lineNum in lineNumber...endLineNumber {
                    lineText = lines[lineNum]
                    if (lineNum == range.end.line) {
                        endIndex = self.index(startIndexOfcurrentLine, offsetBy: range.end.column)
                        break;
                    } else {
                        startIndexOfcurrentLine = self.index(startIndexOfcurrentLine, offsetBy: lineText.count)
                    }
                }
                
                break;
            } else {
                startIndex = self.index(startIndex, offsetBy: lineText.count)
            }
        }
        
        return startIndex..<endIndex
    }

    func indicesOf(_ string: String) -> [String.Index] {
        var indices = [String.Index]()
        var searchStartIndex = self.startIndex
        while searchStartIndex < self.endIndex, let range = self.range(of: string, range: searchStartIndex..<self.endIndex), !range.isEmpty {
//            let IndexDistance: String.IndexDistance = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(range.lowerBound)
            searchStartIndex = range.upperBound
        }
        return indices
    }
}
