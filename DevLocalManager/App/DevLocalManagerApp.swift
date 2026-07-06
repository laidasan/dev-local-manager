import SwiftUI

@main
struct DevLocalManagerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowResizability(.contentSize)
    }
}
