//
//  MarkdownRenderer.swift
//  Notchy
//
//  Renders markdown content to AttributedString using swift-markdown
//

import Foundation
import Markdown
import SwiftUI

/// Renders markdown to AttributedString with terminal-style theming
@MainActor
struct MarkdownRenderer {
    /// Cache parsed documents to avoid re-parsing
    private static let cache = NSCache<NSString, CacheEntry>()

    private final class CacheEntry: @unchecked Sendable {
        let attributedString: AttributedString
        init(_ attributedString: AttributedString) {
            self.attributedString = attributedString
        }
    }

    /// Render markdown string to AttributedString
    static func render(_ markdown: String, fontSize: CGFloat = 12) -> AttributedString {
        let cacheKey = "\(markdown.hashValue)-\(fontSize)" as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached.attributedString
        }

        let document = Document(parsing: markdown)
        var walker = MarkdownWalker(fontSize: fontSize)
        walker.visitDocument(document)

        let result = walker.result
        cache.setObject(CacheEntry(result), forKey: cacheKey)
        return result
    }

    /// Clear the render cache
    static func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Markdown Walker

fileprivate struct MarkdownWalker: MarkupWalker {
    let fontSize: CGFloat
    var result = AttributedString()

    private var listDepth = 0

    init(fontSize: CGFloat) {
        self.fontSize = fontSize
    }

    mutating func visitDocument(_ document: Document) {
        for child in document.children {
            visit(child)
        }
    }

    mutating func visitHeading(_ heading: Heading) {
        let scaleFactor: CGFloat = switch heading.level {
        case 1: 1.5
        case 2: 1.3
        case 3: 1.15
        default: 1.0
        }

        var text = AttributedString()
        for child in heading.children {
            text.append(inlineContent(child))
        }
        text.font = .system(size: fontSize * scaleFactor, weight: .bold)
        text.foregroundColor = .white
        result.append(text)
        result.append(AttributedString("\n"))
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        var text = AttributedString()
        for child in paragraph.children {
            text.append(inlineContent(child))
        }
        result.append(text)
        result.append(AttributedString("\n"))
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let code = codeBlock.code.trimmingCharacters(in: .newlines)
        var text = AttributedString(code)
        text.font = .system(size: fontSize, design: .monospaced)
        text.foregroundColor = TerminalColors.prompt
        text.backgroundColor = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.03)
        result.append(AttributedString("\n"))
        result.append(text)
        result.append(AttributedString("\n\n"))
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        var quoteContent = AttributedString()
        for child in blockQuote.children {
            if let paragraph = child as? Paragraph {
                for inline in paragraph.children {
                    quoteContent.append(inlineContent(inline))
                }
            }
        }

        var prefix = AttributedString("  | ")
        prefix.foregroundColor = TerminalColors.dim
        prefix.font = .system(size: fontSize, design: .monospaced)

        quoteContent.foregroundColor = TerminalColors.dim

        result.append(prefix)
        result.append(quoteContent)
        result.append(AttributedString("\n"))
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        listDepth += 1
        for child in unorderedList.children {
            if let listItem = child as? ListItem {
                visitListItemContent(listItem, ordered: false, index: 0)
            }
        }
        listDepth -= 1
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        listDepth += 1
        var index = Int(orderedList.startIndex)
        for child in orderedList.children {
            if let listItem = child as? ListItem {
                visitListItemContent(listItem, ordered: true, index: index)
                index += 1
            }
        }
        listDepth -= 1
    }

    private mutating func visitListItemContent(_ listItem: ListItem, ordered: Bool, index: Int) {
        let indent = String(repeating: "  ", count: listDepth)
        let bullet = ordered ? "\(index)." : "-"

        var prefix = AttributedString("\(indent)\(bullet) ")
        prefix.foregroundColor = TerminalColors.dim
        prefix.font = .system(size: fontSize)
        result.append(prefix)

        for child in listItem.children {
            if let paragraph = child as? Paragraph {
                for inline in paragraph.children {
                    result.append(inlineContent(inline))
                }
            }
        }
        result.append(AttributedString("\n"))
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        var separator = AttributedString("---\n")
        separator.foregroundColor = TerminalColors.dimmer
        result.append(separator)
    }

    // MARK: - Inline Content

    private func inlineContent(_ markup: any Markup) -> AttributedString {
        switch markup {
        case let text as Markdown.Text:
            var attr = AttributedString(text.string)
            attr.font = .system(size: fontSize)
            attr.foregroundColor = Color.white.opacity(0.9)
            return attr

        case let code as InlineCode:
            var attr = AttributedString(code.code)
            attr.font = .system(size: fontSize, design: .monospaced)
            attr.foregroundColor = TerminalColors.prompt
            attr.backgroundColor = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.03)
            return attr

        case let strong as Strong:
            var combined = AttributedString()
            for child in strong.children {
                combined.append(inlineContent(child))
            }
            combined.font = .system(size: fontSize, weight: .bold)
            return combined

        case let emphasis as Emphasis:
            var combined = AttributedString()
            for child in emphasis.children {
                combined.append(inlineContent(child))
            }
            combined.font = .system(size: fontSize).italic()
            return combined

        case let link as Markdown.Link:
            var combined = AttributedString()
            for child in link.children {
                combined.append(inlineContent(child))
            }
            combined.foregroundColor = TerminalColors.blue
            combined.underlineStyle = .single
            if let dest = link.destination {
                combined.link = URL(string: dest)
            }
            return combined

        case _ as SoftBreak:
            return AttributedString(" ")

        case _ as LineBreak:
            return AttributedString("\n")

        default:
            var attr = AttributedString(markup.format())
            attr.font = .system(size: fontSize)
            attr.foregroundColor = Color.white.opacity(0.9)
            return attr
        }
    }
}
