import AppKit
import SwiftUI
import MementoCore

@MainActor final class Store: ObservableObject {
    @Published var settings: SettingsFile
    @Published var message = ""
    private let key = "settings.v1"
    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do { settings = try SettingsFile.decode(data) }
            catch { settings = SettingsFile(); message = "저장된 설정을 읽지 못했어요. 다시 설정하거나 파일을 가져와 주세요." }
        } else { settings = SettingsFile() }
    }
    func save() {
        do { UserDefaults.standard.set(try JSONEncoder().encode(settings), forKey: key) }
        catch { message = "설정을 저장하지 못했어요. \(error.localizedDescription)" }
    }
    func resetProfile() -> Bool {
        let alert = NSAlert(); alert.messageText = "이 Mac의 기록을 지울까요?"
        alert.informativeText = "생년월일과 오늘의 문장을 지우고 예시 화면으로 돌아갑니다. 웹의 기록은 유지됩니다."
        alert.addButton(withTitle: "취소"); alert.addButton(withTitle: "기록 지우기")
        guard alert.runModal() == .alertSecondButtonReturn else { return false }
        settings.state = LifeState(); save(); message = "이 Mac의 기록을 지웠어요."; return true
    }
    func importFile() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 65536 else { throw LifeError.invalid("설정 파일은 64KB 이하여야 합니다.") }
            let imported = try SettingsFile.decode(Data(contentsOf: url))
            let alert = NSAlert(); alert.messageText = "현재 설정을 가져온 설정으로 바꿀까요?"
            alert.informativeText = "생년월일, 기준 수명, 오늘의 문장과 위젯 디자인이 변경됩니다."
            alert.addButton(withTitle: "가져오기"); alert.addButton(withTitle: "취소")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            settings = imported; save(); message = "설정을 가져왔어요."
        } catch { message = error.localizedDescription }
    }
    func exportFile() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "mementomori-settings.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(settings).write(to: url, options: .atomic); message = "설정 파일을 저장했어요."
        } catch { message = "설정을 내보내지 못했어요. \(error.localizedDescription)" }
    }
}
