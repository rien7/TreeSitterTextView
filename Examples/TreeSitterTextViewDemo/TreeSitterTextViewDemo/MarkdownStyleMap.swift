import TreeSitterTextView

let markdownStyleMap: [String: TSStyle] = [
    "text.title.h1": TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1.4,
        fontWeight: .bold,
        tsNodeType: Set(arrayLiteral: "text.title.h1"),
        priority: 1
    ),
    "text.title.h2": TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1.4,
        fontWeight: .semibold,
        tsNodeType: Set(arrayLiteral: "text.title.h2"),
        priority: 1
    ),
    "text.title.h3": TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1.2,
        fontWeight: .semibold,
        tsNodeType: Set(arrayLiteral: "text.title.h3"),
        priority: 1
    ),
    "text.title.h4": TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1.2,
        fontWeight: .medium,
        tsNodeType: Set(arrayLiteral: "text.title.h4"),
        priority: 1
    ),
    "text.title.h5": TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1.125,
        fontWeight: .medium,
        tsNodeType: Set(arrayLiteral: "text.title.h5"),
        priority: 1
    ),
    "text.title.h6": TSStyle(
        foregroundColor: .textColor,
        backgroundColor: .clear,
        fontSize: 1,
        fontWeight: .medium,
        tsNodeType: Set(arrayLiteral: "text.title.h6"),
        priority: 1
    ),
    "text.strong": TSStyle(
        fontWeight: .bold,
        tsNodeType: Set(arrayLiteral: "text.strong"),
        priority: 1
    ),
    "text.emphasis": TSStyle(
        fontStyle: .italic,
        tsNodeType: Set(arrayLiteral: "text.emphasis"),
        priority: 2
    ),
    "text.strikethrough": TSStyle(
        fontStyle: .strikethrough,
        tsNodeType: Set(arrayLiteral: "text.strikethrough")
    ),
    "text.code": TSStyle(
        fontStyle: .monospace,
        tsNodeType: Set(arrayLiteral: "text.code")
    ),
    "text.uri": TSStyle(
        foregroundColor: .linkColor,
        tsNodeType: Set(arrayLiteral: "text.uri")
    ),
    "punctuation.delimiter": TSStyle(
        foregroundColor: .gray,
        tsNodeType: Set(arrayLiteral: "punctuation.delimiter"),
        priority: 10
    ),
    "punctuation.special": TSStyle(
        foregroundColor: .gray,
        tsNodeType: Set(arrayLiteral: "punctuation.special"),
        priority: 10
    ),
    "text.reference": TSStyle(
        foregroundColor: .textColor,
        tsNodeType: Set(arrayLiteral: "text.reference")
    ),
]
