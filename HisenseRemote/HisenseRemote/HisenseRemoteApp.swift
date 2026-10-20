import SwiftUI

@main
struct HisenseRemoteApp: App {
    @StateObject private var vm = RemoteViewModel()
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(store)
                .onAppear {
                    #if DEBUG
                    if vm.startDemo(store: store) { return }   // ver Demo.swift
                    #endif
                    vm.start(); store.start()
                }
        }
    }
}
