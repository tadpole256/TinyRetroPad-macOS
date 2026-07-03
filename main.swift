import Cocoa

// ─── Constants ────────────────────────────────────────────────────────

let APP_NAME = "TinyRetroPad"
let WINDOW_WIDTH: CGFloat = 800
let WINDOW_HEIGHT: CGFloat = 640

// ─── App Delegate ─────────────────────────────────────────────────────

final class AppDelegate: NSObject, NSApplicationDelegate {
    var mainController: EditorWindowController?

    @objc func applicationDidFinishLaunching(_ notification: Notification) {
        mainController = EditorWindowController()
        mainController?.showWindow(nil)
    }

    @objc func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @objc func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return mainController?.openFile(URL(fileURLWithPath: filename)) ?? false
    }
}

// ─── Editor View ──────────────────────────────────────────────────────

final class EditorView: NSView, NSTextViewDelegate {
    let scrollView = NSScrollView()
    let textView = NSTextView()
    let statusLabel = NSTextField(labelWithString: "Ln 1, Col 1")

    var wordWrap = true { didSet { applyWordWrap() } }
    var statusBarVisible = true { didSet { doLayout(); statusLabel.isHidden = !statusBarVisible } }

    var currentFileURL: URL?
    var isDirty = false {
        didSet {
            NSApp.mainWindow?.windowController?.synchronizeWindowTitleWithDocumentName()
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    @objc func setup() {
        // Scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        // Text view
        textView.isRichText = false
        textView.isEditable = true
        textView.allowsUndo = true
        textView.delegate = self
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.allowsDocumentBackgroundColorChange = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        scrollView.documentView = textView

        // Status bar
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.drawsBackground = true
        statusLabel.backgroundColor = .controlBackgroundColor
        statusLabel.alignment = .left
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
    }

    override func updateConstraints() {
        super.updateConstraints()
        doLayout()
    }

    @objc func doLayout() {
        NSLayoutConstraint.deactivate(constraints)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            statusLabel.heightAnchor.constraint(equalToConstant: statusBarVisible ? 20 : 0),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor),
        ])
    }

    // MARK: - Text View Delegate

    @objc func textDidChange(_ notification: Notification) {
        isDirty = true
        updateTitle()
    }

    @objc func textViewDidChangeSelection(_ notification: Notification) {
        updateStatus()
    }

    @objc func updateStatus() {
        guard statusBarVisible else { return }
        let sel = textView.selectedRange()
        let str = textView.string as NSString
        let lineStart = str.lineRange(for: sel)
        let lineNum = str.substring(with: NSRange(location: 0, length: sel.location)).components(separatedBy: .newlines).count
        let col = max(sel.location - lineStart.location + 1, 1)
        statusLabel.stringValue = "Ln \(lineNum), Col \(col)"
    }

    @objc func applyWordWrap() {
        scrollView.hasHorizontalScroller = !wordWrap
        if wordWrap {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        } else {
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
    }

    @objc func updateTitle() {
        guard let window = window else { return }
        let name = currentFileURL?.lastPathComponent ?? "Untitled"
        window.title = isDirty ? "\(name) — Edited" : name
        window.isDocumentEdited = isDirty
    }

    // MARK: - File I/O

    @objc func loadFile(_ url: URL) -> Bool {
        let content: String?
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            content = utf8
        } else {
            content = try? String(contentsOf: url, encoding: .isoLatin1)
        }
        guard let text = content else { return false }
        textView.string = text
        currentFileURL = url
        isDirty = false
        updateTitle()
        return true
    }

    @objc func save(to url: URL) -> Bool {
        guard let data = textView.string.data(using: .utf8) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            currentFileURL = url
            isDirty = false
            updateTitle()
            return true
        } catch { return false }
    }

    @objc func hasContent() -> Bool { !textView.string.isEmpty }

    @objc func confirmDiscard() -> Bool {
        guard isDirty else { return true }
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        switch alert.runModal() {
        case .alertFirstButtonReturn: return saveDocument()  // Save
        case .alertSecondButtonReturn: return true           // Don't Save
        default: return false                                 // Cancel
        }
    }

    // MARK: - Actions

    @objc func newDocument() {
        guard confirmDiscard() else { return }
        textView.string = ""
        currentFileURL = nil
        isDirty = false
        updateTitle()
    }

    @objc func openDocument() {
        guard confirmDiscard() else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text, .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        _ = loadFile(url)
    }

    @objc func saveDocument() -> Bool {
        if let url = currentFileURL {
            return save(to: url)
        }
        return saveDocumentAs()
    }

    @objc func saveDocumentAs() -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = currentFileURL?.lastPathComponent ?? "Untitled.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        return save(to: url)
    }

    @objc func pageSetup() { NSPageLayout().runModal() }

    @objc func printDocument() {
        let op = NSPrintOperation(view: textView)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        op.run()
    }

    @objc func toggleWordWrap() {
        wordWrap.toggle()
        if let mi = NSApp.mainMenu?.item(withTitle: "Format")?.submenu?.item(withTitle: "Word Wrap") {
            mi.state = wordWrap ? .on : .off
        }
    }

    @objc func toggleStatusBar() {
        statusBarVisible.toggle()
        statusLabel.isHidden = !statusBarVisible
        doLayout()
        if let mi = NSApp.mainMenu?.item(withTitle: "View")?.submenu?.item(withTitle: "Status Bar") {
            mi.state = statusBarVisible ? .on : .off
        }
    }

    @objc func insertTimeDate() {
        let df = DateFormatter()
        df.dateFormat = "h:mm a  M/d/yyyy"
        textView.insertText(df.string(from: Date()), replacementRange: textView.selectedRange())
    }

    @objc func goToLine() {
        let alert = NSAlert()
        alert.messageText = "Go To Line"
        alert.informativeText = "Line number:"
        alert.addButton(withTitle: "Go")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 150, height: 24))
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        guard alert.runModal() == .alertFirstButtonReturn, let n = Int(input.stringValue), n > 0 else { return }

        let str = textView.string as NSString
        let lines = str.components(separatedBy: .newlines)
        let target = min(n, lines.count)
        var idx = 0
        for i in 1..<target { idx += lines[i - 1].count + 1 }
        let len = min(target <= lines.count ? lines[target - 1].count : 0, str.length - idx)
        textView.setSelectedRange(NSRange(location: min(idx, str.length), length: len))
        textView.scrollRangeToVisible(textView.selectedRange())
    }

    @objc func showFontPanel() {
        NSFontManager.shared.target = self
        NSFontManager.shared.orderFrontFontPanel(nil)
    }

    @objc func changeFont(_ sender: Any?) {
        let new = NSFontManager.shared.convert(textView.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular))
        textView.font = new
    }
}

// ─── Window Controller ────────────────────────────────────────────────

final class EditorWindowController: NSWindowController, NSWindowDelegate {
    let editor = EditorView()

    init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: WINDOW_WIDTH, height: WINDOW_HEIGHT),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        win.contentView = editor
        win.title = "Untitled"
        win.minSize = NSSize(width: 300, height: 200)
        win.setFrameAutosaveName("TinyRetroPadWindow")
        win.isRestorable = true
        win.registerForDraggedTypes([.fileURL])
        super.init(window: win)
        win.delegate = self
        buildMenus()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Drag and Drop

    @objc func window(_ window: NSWindow, draggingEntered sender: NSDraggingInfo) -> NSDragOperation { .copy }

    @objc func window(_ window: NSWindow, performDragOperation sender: NSDraggingInfo) -> Bool {
        guard let url = NSURL(from: sender.draggingPasteboard) as URL? else { return false }
        return openFile(url)
    }

    @objc func openFile(_ url: URL) -> Bool {
        guard editor.confirmDiscard() else { return false }
        return editor.loadFile(url)
    }

    // MARK: - Menu Bar

    @objc func buildMenus() {
        let main = NSMenu()

        // App
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About TinyRetroPad", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit TinyRetroPad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem(); appItem.submenu = appMenu; main.addItem(appItem)

        // File
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New", action: #selector(EditorView.newDocument), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(EditorView.openDocument), keyEquivalent: "o")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(EditorView.saveDocument), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Save As...", action: #selector(EditorView.saveDocumentAs), keyEquivalent: "S")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Page Setup...", action: #selector(EditorView.pageSetup), keyEquivalent: "P")
            .keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(withTitle: "Print...", action: #selector(EditorView.printDocument), keyEquivalent: "p")
        let fileItem = NSMenuItem(); fileItem.submenu = fileMenu; main.addItem(fileItem)

        // Edit
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: String(UnicodeScalar(NSDeleteCharacter)!))
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(.separator())
        // Find submenu
        let findItem = editMenu.addItem(withTitle: "Find", action: nil, keyEquivalent: "")
        let findSub = NSMenu()
        findSub.addItem(withTitle: "Find...", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "f")
        findSub.addItem(withTitle: "Find Next", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "g")
        findSub.addItem(withTitle: "Find Previous", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "G")
        findSub.addItem(withTitle: "Use Selection for Find", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "e")
        findSub.addItem(withTitle: "Jump to Selection", action: #selector(NSTextView.centerSelectionInVisibleArea(_:)), keyEquivalent: "j")
        editMenu.setSubmenu(findSub, for: findItem)
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Go To...", action: #selector(EditorView.goToLine), keyEquivalent: "l")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Time/Date", action: #selector(EditorView.insertTimeDate), keyEquivalent: "t")
            .keyEquivalentModifierMask = [.command, .shift]
        let editItem = NSMenuItem(); editItem.submenu = editMenu; main.addItem(editItem)

        // Format
        let formatMenu = NSMenu(title: "Format")
        let wrapItem = formatMenu.addItem(withTitle: "Word Wrap", action: #selector(EditorView.toggleWordWrap), keyEquivalent: "")
        wrapItem.state = .on
        // Font submenu
        let fontItem = formatMenu.addItem(withTitle: "Font", action: nil, keyEquivalent: "")
        let fontSub = NSMenu()
        fontSub.addItem(withTitle: "Show Fonts", action: #selector(EditorView.showFontPanel), keyEquivalent: "t")
        fontSub.addItem(withTitle: "Bigger", action: #selector(NSFontManager.modifyFont(_:)), keyEquivalent: "+")
        fontSub.addItem(withTitle: "Smaller", action: #selector(NSFontManager.modifyFont(_:)), keyEquivalent: "-")
        formatMenu.setSubmenu(fontSub, for: fontItem)
        let fmtItem = NSMenuItem(); fmtItem.submenu = formatMenu; main.addItem(fmtItem)

        // View
        let viewMenu = NSMenu(title: "View")
        let sbItem = viewMenu.addItem(withTitle: "Status Bar", action: #selector(EditorView.toggleStatusBar), keyEquivalent: "/")
        sbItem.state = .on
        let viewItem = NSMenuItem(); viewItem.submenu = viewMenu; main.addItem(viewItem)

        // Window
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        let winItem = NSMenuItem(); winItem.submenu = windowMenu; main.addItem(winItem)

        // Help
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "TinyRetroPad Help", action: #selector(openHelp), keyEquivalent: "?")
        let helpItem = NSMenuItem(); helpItem.submenu = helpMenu; main.addItem(helpItem)

        NSApp.mainMenu = main
        // Auto-enable items (Undo/Redo/Cut/Copy/Paste/etc.)
        NSApp.mainMenu?.autoenablesItems = true
    }

    @objc func openHelp() {
        NSWorkspace.shared.open(URL(string: "https://github.com/PlummersSoftwareLLC/TinyRetroPad")!)
    }

    // MARK: - Window close with dirty check

    @objc func windowShouldClose(_ sender: NSWindow) -> Bool {
        return editor.confirmDiscard()
    }
}

// ─── App Entry ────────────────────────────────────────────────────────

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
