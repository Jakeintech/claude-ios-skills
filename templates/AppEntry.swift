import SwiftUI

@main
struct __APP_NAME__App: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Text("Welcome to __APP_NAME__")
                .font(.largeTitle)
                .fontDesign(.serif)
        }
    }
}
