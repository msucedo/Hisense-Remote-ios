import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: RemoteViewModel
    @EnvironmentObject var store: Store

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
            Group {
                switch vm.screen {
                case .scanning: scanning
                case .pickTV:   pickTV
                case .pairing:  pairing
                case .remote:   RemoteView()
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            // Siempre a la mano (también sin tele, para el revisor de Apple).
            if !store.isFull && vm.screen != .pairing {
                Button("★ Versión completa") { store.showUpgrade = true }
                    .font(.footnote.bold()).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.25)).clipShape(Capsule())
                    .padding(.trailing)
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $store.showUpgrade) { UpgradeView().environmentObject(store) }
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
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text(vm.status).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                }.padding(.trailing, store.isFull ? 0 : 150)   // deja libre el botón ★

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
                // Apps es de la versión completa: sin ella se ven bloqueadas y
                // al tocarlas se abre la hoja de compra.
                section(store.isFull ? "Apps" : "Apps 🔒") {
                    if store.isFull {
                        chips(vm.apps.map(\.name)) { i in vm.launch(vm.apps[i]) }
                    } else if vm.apps.isEmpty {
                        pill("🔒 Desbloquear Apps") { store.showUpgrade = true }
                    } else {
                        chips(vm.apps.map(\.name)) { _ in store.showUpgrade = true }.opacity(0.45)
                    }
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

// Hoja de compra de la versión completa. Las funciones nuevas de pago se agregan a `features`.
struct UpgradeView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let features = [
        ("square.grid.2x2.fill", "Abre tus apps con un toque", "YouTube, Netflix y todas las de tu tele, sin buscarlas con el D-pad."),
        ("sparkles", "Lo que venga después", "Las próximas funciones de la versión completa, incluidas."),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("Versión completa").font(.largeTitle.bold()).padding(.top, 32)
                Text("Una sola compra, para siempre. Sin anuncios.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features, id: \.1) { icon, title, detail in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: icon).font(.title2).foregroundStyle(Color.accentColor).frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.headline)
                                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                if store.isFull {
                    Label("¡Ya tienes la versión completa!", systemImage: "checkmark.seal.fill")
                        .font(.headline).foregroundStyle(.green)
                    Button("Listo") { dismiss() }
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.accentColor).clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    if let m = store.message {
                        Text(m).font(.footnote).foregroundStyle(.orange).multilineTextAlignment(.center)
                    }
                    Button { Task { await store.buy() } } label: {
                        Group {
                            if store.busy || store.loading { ProgressView().tint(.white) }
                            else { Text(store.product.map { "Comprar por \($0.displayPrice)" } ?? "Reintentar") }
                        }
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .background(Color.accentColor).clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(store.busy || store.loading)   // sin producto, el botón reintenta cargarlo

                    Button("Restaurar compras") { Task { await store.restore() } }
                        .font(.subheadline).disabled(store.busy)
                }
            }
            .padding(24)
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .task { if store.product == nil { await store.loadProduct() } }
    }
}
