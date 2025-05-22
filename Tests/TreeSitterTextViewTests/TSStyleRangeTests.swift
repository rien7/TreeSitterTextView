import Testing
import AppKit
@testable import TreeSitterTextView

struct TSStyleRangeTests {
    typealias Error = TSStyleRange.TSStyleRangeError
    typealias RangeStyle = TSStyleRange.RangeStyle

    @Test func insertOutOfRange() throws {
        let baseStyle = TSStyle()
        try TSStyleRange().replaceStyle(
            in: NSRange(location: 0, length: 0),
            with: baseStyle,
            length: 1
        )

        #expect(throws: Error.InvaildRange) {
            try TSStyleRange()
                .replaceStyle(
                    in: NSRange(location: 1, length: 0),
                    with: baseStyle,
                    length: 1
                )
        }

        #expect(throws: Error.InvaildRange) {
            try TSStyleRange()
                .replaceStyle(
                    in: NSRange(location: -1, length: 0),
                    with: baseStyle,
                    length: 1
                )
        }

        let styleRange = TSStyleRange()
        try styleRange
            .replaceStyle(
                in: NSRange(location: 0, length: 0),
                with: baseStyle,
                length: 5
            )
        #expect(throws: Error.InvaildRange) {
            try styleRange
                .replaceStyle(
                    in: NSRange(location: 6, length: 1),
                    with: baseStyle,
                    length: 1
                )
        }
        #expect(throws: Error.InvaildRange) {
            try styleRange
                .replaceStyle(
                    in: NSRange(location: 4, length: 4),
                    with: baseStyle,
                    length: 2
                )
        }
    }

    @Test func replaceNewStyle() throws {
        let baseStyle = TSStyle()
        let redStyle = TSStyle(foregroundColor: .red)
        let boldStyle = TSStyle(fontWeight: .bold)
        let italicStyle = TSStyle(fontStyle: [.italic])

        let styleRange = TSStyleRange()
        try styleRange
            .replaceStyle(
                in: .init(location: 0, length: 0),
                with: baseStyle,
                length: 10
            )
        try styleRange.checkRangeStyles()
        try styleRange
            .replaceStyle(
                in: .init(location: 5, length: 3),
                with: boldStyle,
                length: 3
            )
        try styleRange.checkRangeStyles()
        try styleRange
            .replaceStyle(
                in: .init(location: 7, length: 0),
                with: redStyle,
                length: 5
            )
        try styleRange.checkRangeStyles()
        var expect: [RangeStyle] = [
            .init(
                range: .init(location: 0, length: 5),
                style: baseStyle,
                isModified: true
            ),
            .init(
                range: .init(location: 5, length: 2),
                style: boldStyle,
                isModified: true
            ),
            .init(
                range: .init(location: 7, length: 5),
                style: redStyle,
                isModified: true
            ),
            .init(
                range: .init(location: 12, length: 1),
                style: boldStyle,
                isModified: true
            ),
            .init(
                range: .init(location: 13, length: 2),
                style: baseStyle,
                isModified: true
            ),
        ]
        #expect(styleRange.rangeStyles == expect)
        try styleRange
            .replaceStyle(
                in: .init(location: 7, length: 5),
                with: italicStyle,
                length: 5
            )
        try styleRange.checkRangeStyles()
        expect[2].style = italicStyle
        #expect(styleRange.rangeStyles == expect)
    }
}
