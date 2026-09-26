import Foundation
import SwiftUI
import MementoCore
import WidgetKit

@MainActor
final class Store: ObservableObject {
    @Published private(set) var settings: SettingsFile
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = defaults.data(forKey: "settings.v1").flatMap { try? SettingsFile.decode($0) } ?? SharedSettings.read() ?? SettingsFile()
        SharedSettings.write(settings)
        WidgetCenter.shared.reloadAllTimelines()
    }
    func save(_ value: SettingsFile) throws {
        let valid = try value.validated()
        let data = try JSONEncoder().encode(valid)
        defaults.set(data, forKey: "settings.v1")
        settings = valid
        SharedSettings.write(valid)
        WidgetCenter.shared.reloadAllTimelines()
    }
    func mode(_ mode: String) {
        var value = settings; value.state.mode = mode
        try? save(value)
    }
    func reset() {
        defaults.removeObject(forKey: "settings.v1")
        settings = SettingsFile()
        SharedSettings.write(settings)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
