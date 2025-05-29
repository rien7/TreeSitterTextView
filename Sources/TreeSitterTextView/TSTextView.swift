import AppKit
import SwiftTreeSitter
import SwiftTreeSitterLayer

open class TSTextView: NSTextView {
    private var lastStyleRange: TSStyleRange?
    private var rootLayer: LanguageLayer?
    private var styleMap: [String: TSStyle] = [:]
    private var selectedRangeBeforeMark: NSRange?
    private var skipNodeType: Set<String> = Set()

    private var baseFontSize: CGFloat = 16
    private var baseFontWeight: NSFont.Weight = .regular
    
    private var renderItem: DispatchWorkItem?

    // MARK: - Public Function
    
    public func setupTreeSitter(
        languageConfig: LanguageConfiguration,
        configuration: LanguageLayer.Configuration,
    ) {
        do {
            self.rootLayer = try LanguageLayer(
                languageConfig: languageConfig,
                configuration: configuration
            )
        } catch {
            print("[TSTextView] Failed to setup treesitter: \(error)")
        }
    }
    
    public func disableTreeSitter() {
        self.rootLayer = nil
        self.lastStyleRange = nil
    }
    
    public func setupEditor(
        baseFontSize: CGFloat = 16,
        baseFontWeight: NSFont.Weight = .regular,
        styleMap: [String: TSStyle] = [:],
        skipNodeType: Set<String> = Set()
    ) {
        self.baseFontSize = baseFontSize
        self.baseFontWeight = baseFontWeight
        self.styleMap = styleMap
        self.skipNodeType = skipNodeType
    }
    
    // MARK: - Override Function
    
    override open func setMarkedText(
        _ string: Any,
        selectedRange: NSRange,
        replacementRange: NSRange
    ) {
        let range = selectedRangeBeforeMark ?? self.selectedRange()
        if selectedRangeBeforeMark == nil {
            selectedRangeBeforeMark = range
        }
        let str = getStringFrom(string)
        var inputAttributes = getInputTextAttribute(self.string, selectedRange: range)
        self.typingAttributes = inputAttributes
        inputAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        inputAttributes[.underlineColor] = NSColor.controlAccentColor
        super.setMarkedText(
            NSAttributedString(string: str, attributes: inputAttributes),
            selectedRange: selectedRange,
            replacementRange: replacementRange
        )
    }

    override open func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?)
        -> Bool
    {
        if !self.hasMarkedText() {
            self.changeLastStyleRange(in: affectedCharRange, length: replacementString?.count ?? 0)
        }
//        self.changeLastLayer(
//            getNewText(
//                in: affectedCharRange,
//                replacementString: replacementString
//            ),
//            with: buildInputEdit(
//                in: affectedCharRange,
//                replacementString: replacementString
//            )
//        )
        return super.shouldChangeText(
            in: affectedCharRange,
            replacementString: replacementString
        )
    }

    override open func insertText(_ string: Any, replacementRange: NSRange) {
        let range = self.selectedRangeBeforeMark ?? self.selectedRange()
        let str = getStringFrom(string)
        var attributeString = getAttributeStringWithoutMark()
        if !str.isEmpty && range.location >= 0 && range.location <= str.count {
            attributeString.insert(.init(string: str), at: range.location)
        }
        let inputAttributes = getInputTextAttribute(
            attributeString.string,
            selectedRange: range
        )
        self.typingAttributes = inputAttributes
        super.insertText(
            NSAttributedString(string: str, attributes: inputAttributes),
            replacementRange: replacementRange)
        self.selectedRangeBeforeMark = nil
    }
    
    override open func didChangeText() {
        super.didChangeText()
        self.scheduleRenderTreesitter()
    }

    public func scheduleRenderTreesitter() {
        renderItem?.cancel()
        renderItem = DispatchWorkItem(qos: .userInteractive) { [weak self] in
            guard let self else { return }
            do {
                try self.renderTreesitter()
            } catch {
                print("[TSTextView] Render markdown error: \(error)")
            }
        }
        if let renderItem = renderItem {
            DispatchQueue.main
                .asyncAfter(
                    deadline: .now() + .milliseconds(50),
                    execute: renderItem
                )
        }
    }

    // MARK: - Private Util Function

    func renderTreesitter() throws {
        guard let layer = rootLayer, !self.hasMarkedText() else { return }
        let string = self.string
        let attributeString = self.attributedString()
        let totalRange = NSRange(string.startIndex..<string.endIndex, in: string)
        let textProvider = string.predicateTextProvider
        layer.replaceContent(with: "\(string)\n")
        let highlight = try layer.highlights(in: totalRange, provider: textProvider)

        let newStyleRange = TSStyleRange.build(from: highlight, with: self.styleMap)
        var rangeStyles = newStyleRange.rangeStyles
        var modifyRanges = Set<NSRange>()
        
        if let lastStyleRange = lastStyleRange {
            rangeStyles = TSStyleRange
                .getDiffRangeStyle(
                    old: lastStyleRange,
                    new: newStyleRange,
                    baseStyle: .Base
                )
            modifyRanges = Set(rangeStyles.map { $0.range })
        }
        var rangeAttrs: [(
            range: NSRange,
            attrs: [NSAttributedString.Key: Any]
        )] = []
        for rangeStyle in rangeStyles {
            let range = rangeStyle.range
            let attrs = rangeStyle.style.toAttrs(
                baseFontSize: baseFontSize,
                baseFontWeight: baseFontWeight
            )
            if modifyRanges.contains(range) {
                modifyRanges.remove(range)
            }
            rangeAttrs.append((range, attrs))
        }
        
        if let textStorage = self.textStorage {
            textStorage.beginEditing()
            for (range, var attrs) in rangeAttrs {
                guard range.upperBound <= string.count else { continue }
                let existNodeType = attributeString.attribute(
                    .treesitterNodeType,
                    at: range.location,
                    effectiveRange: nil
                ) as? Set<String> ?? Set()
                let newNodeType = attrs[.treesitterNodeType] as? Set<String> ?? Set()
                guard existNodeType != newNodeType else { continue }

                var font = attrs[.font] as? NSFont ?? .systemFont(
                    ofSize: baseFontSize,
                    weight: baseFontWeight
                )
                if !font.fontDescriptor.symbolicTraits.contains(.monoSpace) {
                    font = getDynamicSystemFont(
                        text: attributeString.string,
                        baseFont: font
                    )
                }
                attrs[.font] = font
                attrs[.paragraphStyle] = self.defaultParagraphStyle
                textStorage.addAttributes(attrs, range: range)
            }
            textStorage.endEditing()
        }
        
        lastStyleRange = newStyleRange
    }

    func getInputTextAttribute(_ string: String, selectedRange: NSRange)
        -> [NSAttributedString.Key: Any]
    {
        var attrs: [NSAttributedString.Key: Any] = [:]
        let baseAttrStyle = TSStyle.Base.toAttrs(
            baseFontSize: baseFontSize,
            baseFontWeight: baseFontWeight
        )
        let lastAttributeString = getAttributeStringWithoutMark(
            in: NSRange(location: selectedRange.location - 1, length: 1)
        )
        let nextAttributeString = getAttributeStringWithoutMark(
            in: NSRange(location: selectedRange.location, length: 1)
        )
        if lastAttributeString == nil {
            // Start of text
            attrs = baseAttrStyle
        } else if lastAttributeString!.string == "\n" {
            // Start of new line
            attrs = baseAttrStyle
        } else if let nodeType: Set<String> = lastAttributeString!.attribute(
            .treesitterNodeType,
            at: 0,
            effectiveRange: nil
        ) as? Set<String>,
              !nodeType.isDisjoint(with: skipNodeType)
        {
            // Last not skipNodeType
            attrs = nextAttributeString?.attributes(at: 0, effectiveRange: nil) ?? baseAttrStyle
        } else if let nodeType: Set<String> = nextAttributeString?.attribute(
            .treesitterNodeType,
            at: 0,
            effectiveRange: nil
        ) as? Set<String>,
              !nodeType.isDisjoint(with: skipNodeType)
        {
            // Next not skipNodeType
            attrs = lastAttributeString?.attributes(at: 0, effectiveRange: nil) ?? baseAttrStyle
        } else {
            // baseType
            attrs = baseAttrStyle
        }
        let attrFont =
            attrs[.font] as? NSFont
            ?? NSFont.systemFont(
                ofSize: baseFontSize,
                weight: baseFontWeight
            )
        let font = getDynamicSystemFont(text: string, baseFont: attrFont)
        attrs[NSAttributedString.Key("NSOriginalFont")] = font
        attrs[.font] = font
        attrs[.paragraphStyle] = self.defaultParagraphStyle
        return attrs
    }

    func getAttributeStringWithoutMark(in range: NSRange) -> NSAttributedString? {
        let attributedString = getAttributeStringWithoutMark()
        guard range.lowerBound >= 0 && range.upperBound <= attributedString.length
        else { return nil }
        return attributedString.attributedSubstring(from: range)
    }

    func getAttributeStringWithoutMark() -> NSMutableAttributedString {
        let attributeString = self.attributedString()
        let markedRange = self.markedRange()
        var attributeStringWithoutMark = NSMutableAttributedString(
            attributedString: attributeString
        )
        attributeStringWithoutMark.deleteCharacters(in: markedRange)
        return attributeStringWithoutMark
    }

    func changeLastStyleRange(in affectedCharRange: NSRange, length: Int) {
        if let lastStyleRange = lastStyleRange {
            try? lastStyleRange.replaceStyle(
                in: affectedCharRange,
                with: TSStyle.Empty,
                length: length
            )
        }
    }

    func changeLastLayer(_ text: String, with inputEdit: InputEdit) {
        if let layer = rootLayer {
            let _ = layer.didChangeContent(.init(string: text), using: inputEdit)
        }
    }

    func getNewText(in affectedCharRange: NSRange, replacementString: String?) -> String {
        let currentText = self.string as NSString
        let replacement: String = replacementString ?? ""
        let newText = currentText.replacingCharacters(
            in: affectedCharRange,
            with: replacement
        )
        return newText
    }

    func buildInputEdit(in affectedCharRange: NSRange, replacementString: String?) -> InputEdit {
        let replacement: String = replacementString ?? ""
        let newText = getNewText(
            in: affectedCharRange,
            replacementString: replacementString
        )

        let rangeByte = affectedCharRange.byteRange
        let startByte = rangeByte.lowerBound
        let oldEndByte = rangeByte.upperBound
        let newEndByte = startByte + UInt32(replacement.utf8.count)

        let startPoint = indexToPoint(affectedCharRange.lowerBound)
        let oldEndPoint = indexToPoint(affectedCharRange.upperBound)
        let newEndPoint = indexToPoint(
            affectedCharRange.lowerBound + replacement.count, newText: newText)

        return InputEdit(
            startByte: startByte,
            oldEndByte: oldEndByte,
            newEndByte: newEndByte,
            startPoint: startPoint ?? .zero,
            oldEndPoint: oldEndPoint ?? .zero,
            newEndPoint: newEndPoint ?? .zero
        )
    }

    func indexToPoint(_ idx: Int, newText: String? = nil) -> Point? {
        let currentText = newText ?? self.string
        guard idx >= 0 && idx < currentText.count else { return nil }
        let lines = currentText.components(separatedBy: .newlines)

        var currentCharIndex = 0
        var row: UInt32 = 0

        for line in lines {
            let charCount = (line as NSString).length
            if currentCharIndex + charCount >= idx {
                let charOffset = idx - currentCharIndex
                let subString = (line as NSString).substring(
                    to: max(0, charOffset)
                )
                let col = UInt32(subString.utf8.count)
                return Point(row: row, column: col)
            }
            currentCharIndex += charCount + 1
            row += 1
        }

        if idx == currentCharIndex {
            let lastLine = lines.last ?? ""
            let column = UInt32(lastLine.utf8.count)
            return Point(row: row, column: column)
        }

        return nil
    }

    private func getStringFrom(_ string: Any) -> String {
        let str: String
        if let _str = string as? NSAttributedString {
            str = _str.string
        } else if let _str = string as? String {
            str = _str
        } else {
            str = ""
        }
        return str
    }
}

func getDynamicSystemFont(text: String, baseFont: NSFont) -> NSFont {
    guard !text.isEmpty else { return baseFont }
    let ctFont = CTFontCreateForString(
        baseFont, text as CFString, CFRange(location: 0, length: text.utf16.count))
    return ctFont as NSFont
}

extension TSStyleRange {
    static func build(from nameRanges: [NamedRange], with styleMap: [String: TSStyle])
        -> TSStyleRange
    {
        var rangeStyles: [(range: NSRange, style: TSStyle)] = []
        for nameRange in nameRanges {
            if let style = styleMap[nameRange.name] {
                rangeStyles.append((nameRange.range, style))
            } else {
                print("[TSTextView] Cannot get the style for: \"\(nameRange.name)\"")
                rangeStyles.append((nameRange.range, TSStyle.Base))
            }
        }
        return TSStyleRange.build(rangeStyles)
    }
}
