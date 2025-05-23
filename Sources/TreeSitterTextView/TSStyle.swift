import AppKit

public struct TSStyle: Sendable {
    public struct FontStyle: OptionSet, Sendable {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public let rawValue: Int

        public static let none = FontStyle(rawValue: 0 << 0)
        public static let clear = FontStyle(rawValue: 1 << 0)
        public static let italic = FontStyle(rawValue: 1 << 1)
        public static let strikethrough = FontStyle(rawValue: 1 << 2)
        public static let monospace = FontStyle(rawValue: 1 << 3)
    }

    public init(
        foregroundColor: NSColor? = nil,
        backgroundColor: NSColor? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: NSFont.Weight? = nil,
        fontStyle: FontStyle = .none,
        tsNodeType: Set<String> = Set(),
        priority: Int = 0
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
        self.tsNodeType = tsNodeType
        self.priority = priority
    }

    public var foregroundColor: NSColor?
    public var backgroundColor: NSColor?
    public var fontSize: CGFloat?
    public var fontWeight: NSFont.Weight?
    public var fontStyle: FontStyle = .none

    public var tsNodeType: Set<String> = Set()
    public var priority: Int = 0
}

extension TSStyle {
    public static let Empty = TSStyle(
        foregroundColor: nil,
        backgroundColor: nil,
        fontSize: nil,
        fontWeight: nil,
        fontStyle: .none,
        tsNodeType: [],
        priority: -1
    )
    public static let Base = TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1,
        fontWeight: nil,
        fontStyle: .none,
        tsNodeType: [],
        priority: 0
    )
    public func merge(_ rhs: TSStyle) -> TSStyle {
        let higher = rhs.priority >= self.priority ? rhs : self
        let lower = rhs.priority >= self.priority ? self : rhs

        return TSStyle(
            foregroundColor: higher.foregroundColor ?? lower.foregroundColor,
            backgroundColor: higher.backgroundColor ?? lower.backgroundColor,
            fontSize: higher.fontSize ?? lower.fontSize,
            fontWeight: higher.fontWeight ?? lower.fontWeight,
            fontStyle: [self.fontStyle, rhs.fontStyle],
            tsNodeType: self.tsNodeType.union(rhs.tsNodeType),
            priority: max(lower.priority, higher.priority)
        )
    }

    public func toAttrs(baseFontSize: CGFloat, baseFontWeight: NSFont.Weight) -> [NSAttributedString
        .Key:
        Any]
    {
        var attr: [NSAttributedString.Key: Any] = [:]
        attr[.foregroundColor] = self.foregroundColor
        attr[.backgroundColor] = self.backgroundColor
        attr[.treesitterNodeType] = self.tsNodeType
        if self.fontStyle.contains(.clear) {
            attr[.strikethroughStyle] = nil
            let fontSize = (self.fontSize ?? 1) * baseFontSize
            let fontWeight = self.fontWeight ?? baseFontWeight
            attr[.font] = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
        } else {
            if self.fontStyle.contains(.strikethrough) {
                attr[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }

            let fontSize = (self.fontSize ?? 1) * baseFontSize
            let fontWeight = self.fontWeight ?? baseFontWeight
            var font = self.fontStyle.contains(.monospace)
                ? NSFont.monospacedSystemFont(ofSize: fontSize, weight: fontWeight)
                : NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
            if self.fontStyle.contains(.italic) {
                let currentFontTraits = NSFontManager.shared.traits(of: font)
                font = NSFontManager.shared.convert(
                    font,
                    toHaveTrait: [.italicFontMask, currentFontTraits]
                )
            }
            attr[.font] = font
        }
        return attr
    }
}

extension TSStyle: Equatable {
    public static func == (lhs: TSStyle, rhs: TSStyle) -> Bool {
        lhs.foregroundColor == rhs.foregroundColor
            && lhs.backgroundColor == rhs.backgroundColor
            && lhs.fontSize == rhs.fontSize
            && lhs.fontWeight == rhs.fontWeight
            && lhs.fontStyle == rhs.fontStyle
            && lhs.tsNodeType == rhs.tsNodeType
    }
}

extension NSAttributedString.Key {
    public static let treesitterNodeType = NSAttributedString.Key("treesitterNodeType")
}
