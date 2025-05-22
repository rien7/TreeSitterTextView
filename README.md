# TreeSitterTextView

TreeSitterTextView is a Swift library that integrates the [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) parsing library with AppKit's `NSTextView` to provide syntax highlighting and text styling for macOS applications. This repository provides a customizable text view (`TSTextView`) that leverages Tree-sitter to parse and style text based on language-specific syntax, making it ideal for code editors, markdown editors, or other text-based applications requiring advanced syntax highlighting.

## Features

- **Syntax Highlighting**: Uses Tree-sitter to parse text and apply styles based on language syntax.
- **Customizable Styles**: Define styles (`TSStyle`) with properties like foreground/background colors, font size, font weight, and font styles (italic, strikethrough, monospace).
- **Dynamic Text Updates**: Automatically updates syntax highlighting as the user types, with efficient diff-based rendering.
- **Flexible Configuration**: Supports custom language configurations and style mappings for different syntax nodes.
- **macOS Integration**: Built on `NSTextView` for seamless integration with AppKit-based applications.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/rien7/TreeSitterTextView.git", branch: "main"),
]
```

## Usage

### Setting Up the Text View

1. **Initialize `TSTextView`**:
    Create an instance of `TSTextView` in your macOS application, typically within a view controller or window.

    ```swift
    import AppKit
    import TreeSitterTextView

    let textView = TSTextView()
    ```

2. **Configure Tree-sitter**:
    Set up the Tree-sitter language configuration for the desired programming language (e.g., Swift, Python, etc.).

    ```swift
    import SwiftTreeSitter
    import SwiftTreeSitterLayer
    import TreeSitterMarkdown
    import TreeSitterMarkdownInline

    let markdownConfig = try LanguageConfiguration(tree_sitter_markdown(), name: "Markdown")
    let markdownInlineConfig = try LanguageConfiguration(
        tree_sitter_markdown_inline(),
        name: "MarkdownInline",
        bundleName: "TreeSitterMarkdown_TreeSitterMarkdownInline"
    )
        
    let config = LanguageLayer.Configuration(
        languageProvider: {
            name in
            switch name {
            case "markdown":
                return markdownConfig
            case "markdown_inline":
                return markdownInlineConfig
            default:
                return nil
            }
        }
    )
    tsTextView
        .setupTreeSitter(
            languageConfig: markdownConfig,
            configuration: config
        )
    ```

3. **Configure Editor Styles**:
   Define a style map to associate Tree-sitter node types with specific `TSStyle` configurations.

   ```swift
   let styleMap: [String: TSStyle] = [
       "keyword": TSStyle(
           foregroundColor: .systemBlue,
           fontStyle: .italic,
           tsNodeType: ["keyword"],
           priority: 1
       ),
       "string": TSStyle(
           foregroundColor: .systemRed,
           fontStyle: .none,
           tsNodeType: ["string"],
           priority: 1
       ),
       "comment": TSStyle(
           foregroundColor: .systemGreen,
           fontStyle: .italic,
           tsNodeType: ["comment"],
           priority: 1
       )
   ]

   textView.setupEditor(
       baseFontSize: 16,
       baseFontWeight: .regular,
       styleMap: styleMap,
       paragraphStyle: nil,
       skipNodeType: ["delimiter", "punctuation"]
   )
   ```

4. **Add to View Hierarchy**:
   Add the `TSTextView` to your view or window.

   ```swift
   let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
   scrollView.documentView = textView
   view.addSubview(scrollView)
   ```

### Handling Text Input

- The `TSTextView` automatically handles text input and updates syntax highlighting as the user types.
- The `scheduleRenderTreesitter` method ensures efficient rendering by debouncing updates (50ms delay).
- Use `skipNodeType` to ignore certain node types (e.g., delimiters) when applying styles.

### Customizing Styles

- **TSStyle**: Define styles for different syntax nodes with properties like `foregroundColor`, `backgroundColor`, `fontSize`, `fontWeight`, and `fontStyle` (e.g., italic, strikethrough, monospace).
- **Merging Styles**: The `merge` method combines styles based on priority, allowing flexible style composition.
- **Dynamic Fonts**: The `getDynamicSystemFont` function adjusts fonts based on input text, ensuring proper rendering for special characters.

### Example

Check `Examples/TreeSitterTextViewDemo`.

Here’s a part of example to set up a `TSTextView` for Swift code:

```swift
import SwiftUI
import TreeSitterTextView
import SwiftTreeSitter
import SwiftTreeSitterLayer
import TreeSitterMarkdown
import TreeSitterMarkdownInline

struct TSTextViewWrapper: NSViewRepresentable {
    typealias NSViewType = TSTextView

    func makeNSView(context: Context) -> TSTextView {
        let tsTextView = TSTextView()
        do {
            let markdownConfig = try LanguageConfiguration(tree_sitter_markdown(), name: "Markdown")
            let markdownInlineConfig = try LanguageConfiguration(
                tree_sitter_markdown_inline(),
                name: "MarkdownInline",
                bundleName: "TreeSitterMarkdown_TreeSitterMarkdownInline"
            )
            
            let config = LanguageLayer.Configuration(
                languageProvider: {
                    name in
                    switch name {
                    case "markdown":
                        return markdownConfig
                    case "markdown_inline":
                        return markdownInlineConfig
                    default:
                        return nil
                    }
                }
            )
            tsTextView
                .setupTreeSitter(
                    languageConfig: markdownConfig,
                    configuration: config
                )
        } catch {
            print("Fail to setup TSTextView")
        }
        tsTextView.translatesAutoresizingMaskIntoConstraints = false
        return tsTextView
    }
    
    func updateNSView(_ nsView: TSTextView, context: Context) {
    }
}
```

## API Overview

- **TSStyle**:
  - Defines text styling properties (colors, font size, weight, style).
  - Supports merging styles with priority-based resolution.
  - Converts styles to `NSAttributedString` attributes for rendering.

- **TSTextView**:
  - Extends `NSTextView` to integrate Tree-sitter parsing.
  - Manages syntax highlighting and text updates.
  - Supports custom language configurations and style mappings.

- **TSStyleRange**:
  - Manages ranges of text with associated styles.
  - Handles style merging and range updates for efficient rendering.
  - Provides diff-based updates to minimize redraws.

## Contributing

Contributions are welcome! Please submit issues or pull requests to the repository. Ensure any changes include appropriate tests and documentation.

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Acknowledgments

- Built with [SwiftTreeSitter](https://github.com/ChimeHQ/SwiftTreeSitter) for Tree-sitter integration.
- Inspired by modern code editors with syntax highlighting needs.
