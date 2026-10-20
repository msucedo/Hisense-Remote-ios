import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: RemoteViewModel

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
            switch vm.screen {
            case .scanning: scanning
            case .pickTV:   pickTV
            case .pairing:  pairing
            case .remote:   RemoteView()
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
    }

    private var scanning: some View {
        VStack(spacing: 16) {
            if vm.busy { ProgressView().tint(.white) }
            Text(vm.status).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if !vm.busy {
                Button("Buscar de nuevo") { vm.scan() }.buttonStyle(.bordered).tint(.white)
            }
        }.padding(32)
    }

    private var pickTV: some View {
        VStack(spacing: 12) {
            Text("Elige tu TV").font(.headline)
            ForEach(vm.tvs, id: \.self) { ip in
                Button(ip) { vm.connect(ip) }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }.padding()
    }

    private var pairing: some View {
        VStack(spacing: 18) {
            Text("Emparejar").font(.title2.bold())
            Text(vm.status).foregroundStyle(.secondary).multilineTextAlignment(.center)
            TextField("PIN", text: $vm.pin)
                .keyboardType(.numberPad).multilineTextAlignment(.center)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .padding().background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
            Button("Enviar PIN") { vm.submitPin() }
                .frame(maxWidth: .infinity).padding()
                .background(Color.accentColor).clipShape(RoundedRectangle(cornerRadius: 12))
        }.padding(32)
    }
}

// Pantalla del control remoto.
struct RemoteView: View {
    @EnvironmentObject var vm: RemoteViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text(vm.status).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                }

                big("⏻  Encender / Apagar", color: .accentColor) { vm.key("power") }

                dpad

                HStack(spacing: 12) {
                    pill("↩︎") { vm.key("back") }
                    pill("⌂") { vm.key("home") }
                    pill("☰") { vm.key("menu") }
                }

                HStack(spacing: 12) {
                    pill("🔉 −") { vm.volDown() }
                    VStack { Text(vm.volume.map(String.init) ?? "—").font(.title2.bold())
                        Text("volumen").font(.caption2).foregroundStyle(.secondary) }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))
                    pill("🔊 +") { vm.volUp() }
                }
                pill("🔇 Silenciar") { vm.key("mute") }

                section("Fuentes") {
                    chips(vm.sources.map(\.name)) { i in vm.setSource(vm.sources[i]) }
                }
                section("Apps") {
                    chips(vm.apps.map(\.name)) { i in vm.launch(vm.apps[i]) }
                }
            }
            .padding()
        }
    }

    private var dpad: some View {
        VStack(spacing: 8) {
            arrow("▲") { vm.key("up") }
            HStack(spacing: 8) {
                arrow("◀") { vm.key("left") }
                Button("OK") { vm.key("ok") }
                    .frame(width: 80, height: 80).background(Color.white.opacity(0.15)).clipShape(Circle())
                arrow("▶") { vm.key("right") }
            }
            arrow("▼") { vm.key("down") }
        }
    }

    private func arrow(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(t, action: a).font(.title).frame(width: 80, height: 70)
            .background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    private func pill(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(t, action: a).frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    private func big(_ t: String, color: Color, _ a: @escaping () -> Void) -> some View {
        Button(t, action: a).font(.headline).frame(maxWidth: .infinity, minHeight: 52)
            .background(color).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.caption).foregroundStyle(.secondary)
            content()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func chips(_ names: [String], _ tap: @escaping (Int) -> Void) -> some View {
        let cols = [GridItem(.adaptive(minimum: 100), spacing: 8)]
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(Array(names.enumerated()), id: \.offset) { i, name in
                Button(name) { tap(i) }.lineLimit(1).font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
