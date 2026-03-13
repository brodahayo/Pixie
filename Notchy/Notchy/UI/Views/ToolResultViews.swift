//
//  ToolResultViews.swift
//  Notchy
//
//  Specialized renderers for each Claude Code tool result type
//

import SwiftUI

// MARK: - Dispatcher

/// Routes a ToolResultData to its specialized view
struct ToolResultView: View {
    let result: ToolResultData

    var body: some View {
        switch result {
        case .read(let r): ReadResultView(result: r)
        case .edit(let r): EditResultView(result: r)
        case .write(let r): WriteResultView(result: r)
        case .bash(let r): BashResultView(result: r)
        case .grep(let r): GrepResultView(result: r)
        case .glob(let r): GlobResultView(result: r)
        case .todoWrite(let r): TodoWriteResultView(result: r)
        case .task(let r): TaskResultView(result: r)
        case .webFetch(let r): WebFetchResultView(result: r)
        case .webSearch(let r): WebSearchResultView(result: r)
        case .askUserQuestion(let r): AskUserQuestionResultView(result: r)
        case .bashOutput(let r): BashOutputResultView(result: r)
        case .killShell(let r): KillShellResultView(result: r)
        case .exitPlanMode(let r): ExitPlanModeResultView(result: r)
        case .mcp(let r): MCPToolResultView(result: r)
        case .generic(let r): GenericToolResultView(result: r)
        }
    }
}

// MARK: - File Header Component

private struct FilePathHeader: View {
    let icon: String
    let path: String
    let detail: String?

    init(icon: String = "doc", path: String, detail: String? = nil) {
        self.icon = icon
        self.path = path
        self.detail = detail
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(TerminalColors.cyan)
                .font(.system(size: 10))
            Text(URL(fileURLWithPath: path).lastPathComponent)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            if let detail {
                Text(detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TerminalColors.dim)
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(TerminalColors.background)
        .cornerRadius(4)
    }
}

// MARK: - File List Component

private struct FileListView: View {
    let files: [String]
    private let maxVisible = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(files.prefix(maxVisible).enumerated()), id: \.offset) { _, file in
                    Text(URL(fileURLWithPath: file).lastPathComponent)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                if files.count > maxVisible {
                    Text("... and \(files.count - maxVisible) more")
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
        .frame(maxHeight: 120)
        .background(Color.black.opacity(0.3))
        .cornerRadius(4)
    }
}

// MARK: - Read Result

struct ReadResultView: View {
    let result: ReadResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let lineInfo = result.totalLines > result.numLines
                ? "\(result.numLines)/\(result.totalLines) lines"
                : "\(result.numLines) lines"
            FilePathHeader(icon: "doc.text", path: result.filePath, detail: lineInfo)

            ScrollView {
                Text(numberedContent)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
            }
            .frame(maxHeight: 200)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
        }
    }

    private var numberedContent: String {
        let lines = result.content.components(separatedBy: "\n")
        return lines.enumerated().map { i, line in
            let lineNum = result.startLine + i
            return String(format: "%4d | %@", lineNum, line)
        }.joined(separator: "\n")
    }
}

// MARK: - Edit Result

struct EditResultView: View {
    let result: EditResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FilePathHeader(
                icon: "pencil",
                path: result.filePath,
                detail: result.replaceAll ? "replace all" : nil
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(
                        Array(result.oldString.components(separatedBy: "\n").enumerated()),
                        id: \.offset
                    ) { _, line in
                        HStack(spacing: 0) {
                            Text("- ")
                                .foregroundColor(TerminalColors.red)
                            Text(line)
                                .foregroundColor(TerminalColors.red.opacity(0.8))
                        }
                        .font(.system(size: 10, design: .monospaced))
                    }
                    ForEach(
                        Array(result.newString.components(separatedBy: "\n").enumerated()),
                        id: \.offset
                    ) { _, line in
                        HStack(spacing: 0) {
                            Text("+ ")
                                .foregroundColor(TerminalColors.green)
                            Text(line)
                                .foregroundColor(TerminalColors.green.opacity(0.8))
                        }
                        .font(.system(size: 10, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }
            .frame(maxHeight: 200)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
        }
    }
}

// MARK: - Write Result

struct WriteResultView: View {
    let result: WriteResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let action = result.type == .create ? "Created" : "Wrote"
            FilePathHeader(icon: "doc.badge.plus", path: result.filePath, detail: action)

            if !result.content.isEmpty {
                Text(String(result.content.prefix(500)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Bash Result

struct BashResultView: View {
    let result: BashResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if result.interrupted {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(TerminalColors.amber)
                        .font(.system(size: 10))
                    Text("Interrupted")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(TerminalColors.amber)
                }
            }

            if result.hasOutput {
                ScrollView {
                    Text(result.displayOutput)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
                .frame(maxHeight: 200)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
            }
        }
    }
}

// MARK: - Grep Result

struct GrepResultView: View {
    let result: GrepResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(TerminalColors.cyan)
                    .font(.system(size: 10))
                Text("\(result.numFiles) file\(result.numFiles == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }

            if let content = result.content, !content.isEmpty {
                ScrollView {
                    Text(content)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
                .frame(maxHeight: 150)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
            } else if !result.filenames.isEmpty {
                FileListView(files: result.filenames)
            }
        }
    }
}

// MARK: - Glob Result

struct GlobResultView: View {
    let result: GlobResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .foregroundColor(TerminalColors.cyan)
                    .font(.system(size: 10))
                Text("\(result.numFiles) file\(result.numFiles == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                if result.truncated {
                    Text("(truncated)")
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.amber)
                }
                Spacer()
            }

            if !result.filenames.isEmpty {
                FileListView(files: result.filenames)
            }
        }
    }
}

// MARK: - WebFetch Result

struct WebFetchResultView: View {
    let result: WebFetchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .foregroundColor(TerminalColors.blue)
                    .font(.system(size: 10))
                Text(result.url)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TerminalColors.blue)
                    .lineLimit(1)
                Spacer()
                Text("\(result.code)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(result.code == 200 ? TerminalColors.green : TerminalColors.red)
            }

            if !result.result.isEmpty {
                Text(String(result.result.prefix(300)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - WebSearch Result

struct WebSearchResultView: View {
    let result: WebSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(TerminalColors.blue)
                    .font(.system(size: 10))
                Text(result.query)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(result.results.count) results")
                    .font(.system(size: 10))
                    .foregroundColor(TerminalColors.dim)
            }

            ForEach(Array(result.results.prefix(5).enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(TerminalColors.blue)
                        .lineLimit(1)
                    Text(item.snippet)
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.6))
                        .lineLimit(2)
                }
                .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Task Result

struct TaskResultView: View {
    let result: TaskResult

    var body: some View {
        HStack(spacing: 6) {
            Text(result.status.capitalized)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(statusColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.15))
                .cornerRadius(3)

            if let prompt = result.prompt {
                Text(prompt)
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            if let tokens = result.totalTokens {
                Text("\(tokens) tokens")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(TerminalColors.dim)
            }
        }
    }

    private var statusColor: Color {
        switch result.status.lowercased() {
        case "completed", "done": return TerminalColors.green
        case "error", "failed": return TerminalColors.red
        case "running": return TerminalColors.amber
        default: return TerminalColors.dim
        }
    }
}

// MARK: - TodoWrite Result

struct TodoWriteResultView: View {
    let result: TodoWriteResult

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(result.newTodos.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Image(systemName: todoIcon(item.status))
                        .foregroundColor(todoColor(item.status))
                        .font(.system(size: 10))
                    Text(item.content)
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
        }
    }

    private func todoIcon(_ status: String) -> String {
        switch status {
        case "completed": return "checkmark.circle.fill"
        case "in_progress": return "arrow.trianglehead.clockwise.rotate.90"
        default: return "circle"
        }
    }

    private func todoColor(_ status: String) -> Color {
        switch status {
        case "completed": return TerminalColors.green
        case "in_progress": return TerminalColors.amber
        default: return TerminalColors.dim
        }
    }
}

// MARK: - AskUserQuestion Result

struct AskUserQuestionResultView: View {
    let result: AskUserQuestionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(result.questions.enumerated()), id: \.offset) { _, q in
                Text(q.question)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }

            Text("Answer in terminal")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(TerminalColors.amber)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(TerminalColors.amber.opacity(0.1))
                .cornerRadius(3)
        }
    }
}

// MARK: - BashOutput Result

struct BashOutputResultView: View {
    let result: BashOutputResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("Shell \(result.shellId)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalColors.cyan)
                Text(result.status)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TerminalColors.dim)
                if let exitCode = result.exitCode {
                    Text("(\(exitCode))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(exitCode == 0 ? TerminalColors.green : TerminalColors.red)
                }
                Spacer()
            }

            if !result.stdout.isEmpty {
                Text(String(result.stdout.prefix(500)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - KillShell Result

struct KillShellResultView: View {
    let result: KillShellResult

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "xmark.circle")
                .foregroundColor(TerminalColors.red)
                .font(.system(size: 10))
            Text(result.message)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.7))
        }
    }
}

// MARK: - ExitPlanMode Result

struct ExitPlanModeResultView: View {
    let result: ExitPlanModeResult

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "list.bullet.clipboard")
                .foregroundColor(TerminalColors.green)
                .font(.system(size: 10))
            Text("Plan ready")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(TerminalColors.green)
            if result.isAgent {
                Text("(agent)")
                    .font(.system(size: 9))
                    .foregroundColor(TerminalColors.dim)
            }
        }
    }
}

// MARK: - MCP Tool Result

struct MCPToolResultView: View {
    let result: MCPResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "server.rack")
                    .foregroundColor(TerminalColors.magenta)
                    .font(.system(size: 10))
                Text("\(result.serverName):\(result.toolName)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalColors.magenta)
                Spacer()
            }

            if !result.rawResult.isEmpty {
                let display = result.rawResult
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: "\n")
                Text(String(display.prefix(300)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Generic Tool Result (Fallback)

struct GenericToolResultView: View {
    let result: GenericResult

    var body: some View {
        if let content = result.rawContent, !content.isEmpty {
            Text(String(content.prefix(500)))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.7))
                .lineLimit(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
        }
    }
}
