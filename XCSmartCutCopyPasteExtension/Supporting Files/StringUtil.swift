//
//  StringUtil.swift
//
//  Created by Mike Retondo on 9/25/19.
//  Copyright © 2019 Mike Retondo. All rights reserved.
//

import Foundation

extension StringProtocol {

    // [i]
    subscript(i: Int) -> Character {
        return self[self.index(at: i)]
    }

    // [i..<j]
    subscript(range: Range<Int>) -> Self.SubSequence {
        let i = self.index(at: range.lowerBound)
        let j = self.index(at: range.upperBound)
        return self[i..<j]
    }

    // [i...j]
    subscript(range: ClosedRange<Int>) -> Self.SubSequence {
        let i = self.index(at: range.lowerBound)
        let j = self.index(at: range.upperBound)
        return self[i...j]
    }

    // [..<i]
    subscript(range: PartialRangeUpTo<Int>) -> Self.SubSequence {
        let i = self.index(at: range.upperBound)
        return self[..<i]
    }

    // [...i]
    subscript(range: PartialRangeThrough<Int>) -> Self.SubSequence {
        let i = self.index(at: range.upperBound)
        return self[...i]
    }

    // [i...]
    subscript(range: PartialRangeFrom<Int>) -> Self.SubSequence {
        let i = self.index(at: range.lowerBound)
        return self[i...]
    }
}

extension StringProtocol {

    /// Returns the number of bytes used to hold the string. This works because
    /// Swift 5 now uses UTF-8 as it's backing store.
    @inline(__always)
    var size: Int {
        get { self.utf8.count }
    }
}

extension StringProtocol {

    /// Returns an array of indices where 'string' is located with in the string.
    ///
    /// - Parameters:
    ///   - string: The string to search for.
    /// - Returns: An array of String.Index.
    func indices(of string: String) -> [Self.Index] {
        var indices = [Self.Index]()
        var start = self.startIndex
        while start < self.endIndex, let range = self.range(of: string, range: start..<self.endIndex), !range.isEmpty {
            //            let IndexDistance: String.IndexDistance = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(range.lowerBound)
            start = range.upperBound
        }
        return indices
    }

    /// Returns an index that is the specified distance from the start or end of the
    /// string. If 'n' is positive then offset start from the beginning of the string
    /// else from the end of the string.
    ///
    /// The value passed as `n` must not offset beyond the bounds of the collection.
    ///
    /// - Parameters:
    ///   - n: The distance to offset.
    /// - Returns: An index offset by `n`. If `n` is positive, this is the same value
    ///   as the result of `n` calls to `index(after:)`.
    ///   If `n` is negative, this is the same value as the result of `-n` calls
    ///   to `index(before:)`.
    func index(at n: String.IndexDistance) -> Self.Index {
        if n == 0 {
            return self.startIndex
        } else if n >= 0 {
            return self.index(self.startIndex, offsetBy: n)
        } else {
            return self.index(self.endIndex, offsetBy: n)
        }
    }

    @inline(__always)
    func indexRangeFor(range: Range<Int>) -> Range<Self.Index> {
        return self.index(at: range.lowerBound)..<self.index(at: range.upperBound)
    }

    @inline(__always)
    func indexRangeFor(range: ClosedRange<Int>) -> ClosedRange<Self.Index> {
        return self.index(at: range.lowerBound)...self.index(at: range.upperBound)
    }
}

extension StringProtocol {

    /// Returns a subsequence, containing the Range<Int> within.
    ///
    /// - Parameters:
    ///   - range: A half-open interval from a lower bound up to, but not including, an upper bound.
    func substring(with range: Range<Int>) -> Self.SubSequence? {
        let r = 0...self.count

        guard r.contains(range.lowerBound) && r.contains(range.upperBound) else { return nil }

        let start = self.index(at: range.lowerBound)
        let end = self.index(at: range.upperBound)

        return self[start..<end]
    }

    /// Returns a subsequence, containing the ClosedRange<Int> within.
    ///
    /// - Parameters:
    ///   - range: A ClosedRange interval from a lower bound up to, but not including, an upper bound.
    func substring(with range: ClosedRange<Int>) -> Self.SubSequence? {
        let r = 0..<self.count

        guard r.contains(range.lowerBound) && r.contains(range.upperBound) else { return nil }

        let start = self.index(at: range.lowerBound)
        let end = self.index(at: range.upperBound)

        return self[start...end]
    }

    // 'i' can be negitive to go in reverse direction
    func substring(from i: Int) -> Self.SubSequence? {
        guard abs(i) < self.count else { return nil }

        let fromIndex = i >= 0 ? self.index(at: i) : self.index(self.endIndex, offsetBy: i)
        let toIndex   = i >= 0 ? self.endIndex : self.startIndex

        return i >= 0 ? self[fromIndex..<toIndex] : self[toIndex..<fromIndex]
    }

    // 'i' can be negitive to go in reverse direction
    func substring(to i: Int) -> Self.SubSequence? {
        guard abs(i) <= self.count else { return nil }

        let fromIndex = i >= 0 ? self.startIndex : self.endIndex
        let toIndex   = i >= 0 ? self.index(at: i) : self.index(self.endIndex, offsetBy: i)

        return i >= 0 ? self[fromIndex..<toIndex] : self[toIndex..<fromIndex]
    }
}

extension StringProtocol {
    //
    // infixs to complement prefix and suffix
    //

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
    ///   - position: The starting element (charecter) position in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - maxLength: The maximum number of elements to return. `maxLength`
    ///     must be greater than zero. The default for `maxLength` is set so
    ///     is set so the remaining elements of the collection will be returned.
    /// - Returns: A subsequence starting from `position` up to `maxLength`
    ///   elements in the collection.
    func infix(from position: Int, maxLength: Int = Int.max) -> Self.SubSequence {
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
    ///   - position: The starting element (charecter) position in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - predicate: A closure that takes an element of the sequence as its
    ///     argument and returns `true` if the element should be included or
    ///     `false` if it should be excluded. Once the predicate
    ///   returns `false` it will not be called again.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    func infix(from position: Int, while predicate: (Element) throws -> Bool) rethrows -> Self.SubSequence {
        // if 'position' is beyond the last charecter position then set 'start' to 'endIndex'
        let start = index(startIndex, offsetBy: numericCast(position), limitedBy: endIndex) ?? endIndex

        var end = start
        while try end != endIndex && predicate(self[end]) {
            formIndex(after: &end)
        }

        return self[start..<end]
    }

    @inline(__always)
    func infix(from start: String.Index, upTo end: String.Index) -> Self.SubSequence {
        return self[start..<end]
    }

    @inline(__always)
    func infix(from start: String.Index, through end: String.Index) -> Self.SubSequence {
        return self[start...end]
    }
}

extension String {

    /// returns a Strings length as a NSString length
    @inline(__always)
    var length: Int {
        // NSString length is equal to the number of UTF-16 code units
        get { return (self as NSString).length }
    }
}

extension String {

    /// Returns a new string with repeating current string 'count' times
    func repeated(count: Int) -> String {
        return [String].init(repeating: self, count: count).joined()
    }

    /// Returns a new string by replacing matches of pattern with replacement.
    func replacedMatches(of pattern: String, with replacement: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSMakeRange(0, self.utf16.count)

        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
    }

    /// Returns a new string in which all occurrences of a target string
    /// in a specified range of the string are removed.
    func removedOccurrences(of occurrence: String, options: String.CompareOptions = []) -> String {
        return self.replacingOccurrences(of: occurrence, with: "", options: options)
    }
}

extension String {

    /// Returns a new string made by removing all whitespacesAndNewlines.
    func trimmingWhitepaceAndNewlines() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trimmingLeadingWhitepaceAndNewlines() -> String {
        let newString = self

        if let range = rangeOfCharacter(from: .whitespacesAndNewlines, options: [.anchored,]) {
            return String(newString[range.upperBound...]).trimmingLeadingWhitepaceAndNewlines()
        }
        return newString
    }

    func trimmingTrailingWhitepaceAndNewlines() -> String {
        let newString = self

        if let range = rangeOfCharacter(from: .whitespacesAndNewlines, options: [.anchored, .backwards]) {
            return String(newString[..<range.lowerBound]).trimmingTrailingWhitepaceAndNewlines()
        }
        return newString
    }
}

extension String {

    /// Replaces the text within the specified bounds starting at 'position'
    /// and a length of 'maxLength with the given characters.
    /// Calling this method invalidates any existing indices for use with this string.
    ///
    /// - Parameters:
    ///   - position: The starting charecter position in the collection. `position` must be
    ///     greater than or equal to zero.
    ///   - maxLength: The maximum number of elements to modifiy. `maxLength`
    ///     must be greater than or equal to zero.
    ///   - newString: The new newString to add to the string.
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
}

extension String {

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
            newString.replaceSubrange(self.index(at: start)..<self.index(at: start), with: " ")
        } else if end - start == 1 {//If one space
            let range = self.index(at: start)..<self.index(at: end)
            newString.replaceSubrange(range, with: " ")
        } else { //More than one space
            let range = self.index(at: start)..<self.index(at: end)
            newString.replaceSubrange(range, with: " ")
        }
        return (start, newString)
    }

    func selectWord(pin: Int) -> Range<String.Index>? {
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
}
