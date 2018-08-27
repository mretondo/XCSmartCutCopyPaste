# XCSmartCutCopyPaste

Formerly called CutCopyUnselectedLine

The basic function of this extension is to apply Cut and Copy commands to unselected lines (no selection except for the insertion point). The CCP commands replace the work done by the standard Edit commands. They will remember if the text was Cut or Copy in Line mode. The Paste command will know wether to paste in line mode or not.

This is an Xcode SourceEditorCommand Extension that gives Xcode what every major IDE has had since the late 80's. It allows for cutting or coping a line with only a selection point (no selection). Xcode thinks it's a word processor instead of a code editor and doesn't distinguish between line selection and character selection. This means Xcode has no concept of Line Selection Mode. If you copy an entire line you expect pasting it would be in line mode as well i.e. the pasted line(s) will be inserted above the line the cursor is on and NOT at the cursor location like a word processor would do.

Line mode is enabled when the selection starts at the beginning of a line and continues to the last character of a line including its newline character. Currently Line mode is only remembered if all the selections are in line mode. Multiple selections are concatenated together like Xcode does i.e. every selection is separated by a newline character. Be patient when starting Xcode for it takes about 10 seconds or so to load the extension after it launches but will keep it loaded from that point on.

Your going to want a utility like "Keyboard Maestro" so you can map the normal key presses (cmd+X, cmd+C, cmd+V) to either the Extension menu items or the normal Edit menu items. You would never want to mouse to the menus to copy a line, that you be slower then selecting the text manually. You could assign keys to them but they would have to be different key combinations because cmd+C for example, is used in more places then the source editor. To make it easy for you I've included a macro file (https://github.com/mretondo/XCSmartCutCopyPaste/blob/master/XCSmartCutCopyPaste.kmmacros) you can import into "Keyboard Maestro" that will figure out which menu item to select. Example, if you type cmd+C it will select the "Smart Copy" menu item if it's enabled otherwise it will select the Edit menus Copy item. The Extension menu items are only enabled if the focus is in the source editor.

The code has been hacked to death with the only regard to making it work. I beeped learning more and more about how Xcode does CCP so the code needs a good clean up. Some things I did was just to learn Swift features. Example, I used a Tuple when I didn't need too just to learn. I started a Xcode project called CutCopyUnselectedLine which was a real mess structure wise so I replaced it with on. I still don't know where the best place to put files but it's better than it was.

I hope this works well for you and wish Apple would just add this functionality to Xcode.


This project was inspired by the extensions:
https://github.com/kaunteya/LineX
https://github.com/wangshengjia/XcodeEditorPlus


# MIT Licensed:

Created by Mike Retondo on 8/16/18.

Copyright © 2018 Mike Retondo. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This release includes the canviz, path amd prototype JavaScript libraries which are distributed under the terms of their respective licenses.
