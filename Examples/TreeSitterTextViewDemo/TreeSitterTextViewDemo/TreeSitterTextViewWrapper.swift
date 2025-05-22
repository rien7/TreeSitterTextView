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
            tsTextView
                .setupEditor(styleMap: markdownStyleMap, skipNodeType: Set(["punctuation.delimiter"]))
        } catch {
            print("Fail to setup TSTextView")
        }
        tsTextView.translatesAutoresizingMaskIntoConstraints = false
        return tsTextView
    }
    
    func updateNSView(_ nsView: TSTextView, context: Context) {
    }
}
