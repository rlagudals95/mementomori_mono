import SwiftUI
import UniformTypeIdentifiers
import MementoCore

struct SettingsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var settings: SettingsFile
    init(settings: SettingsFile) { self.settings = settings }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw LifeError.invalid("파일을 읽을 수 없습니다.") }
        settings = try SettingsFile.decode(data)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(settings.validated()))
    }
}
