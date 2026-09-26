import SwiftUI

@main
struct MementoMoriApp: App {
    @StateObject private var store = Store()
    init() { Design.registerFont() }
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(store).preferredColorScheme(.light)
                .font(Design.font(15)).tint(Design.ink)
        }
    }
}
