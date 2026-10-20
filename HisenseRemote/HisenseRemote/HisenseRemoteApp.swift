import SwiftUI

@main
struct HisenseRemoteApp: App {
    @StateObject private var vm = RemoteViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .onAppear { vm.start() }
        }
    }
}
