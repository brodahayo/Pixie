import Foundation

enum ToolResultData: Sendable {
    case read(ReadResult)
    case edit(EditResult)
    case write(WriteResult)
    case bash(BashResult)
    case grep(GrepResult)
    case glob(GlobResult)
    case webFetch(WebFetchResult)
    case webSearch(WebSearchResult)
    case task(TaskResult)
    case todoWrite(TodoWriteResult)
    case askUserQuestion(AskUserQuestionResult)
    case mcp(MCPResult)
    case generic(GenericResult)
}

struct ReadResult: Sendable { let filePath: String; let content: String; let lineCount: Int }
struct EditResult: Sendable { let filePath: String; let diff: String; let oldContent: String; let newContent: String }
struct WriteResult: Sendable { let filePath: String; let content: String }
struct BashResult: Sendable { let command: String; let output: String; let exitCode: Int }
struct GrepResult: Sendable { let pattern: String; let matches: [GrepMatch] }
struct GrepMatch: Sendable { let file: String; let line: Int; let content: String }
struct GlobResult: Sendable { let pattern: String; let files: [String] }
struct WebFetchResult: Sendable { let url: String; let content: String }
struct WebSearchResult: Sendable { let query: String; let results: [SearchResultItem] }
struct SearchResultItem: Sendable { let title: String; let url: String; let snippet: String }
struct TaskResult: Sendable { let status: String; let description: String }
struct TodoWriteResult: Sendable { let items: [String] }
struct AskUserQuestionResult: Sendable { let question: String }
struct MCPResult: Sendable { let server: String; let tool: String; let output: String }
struct GenericResult: Sendable { let tool: String; let output: String }
