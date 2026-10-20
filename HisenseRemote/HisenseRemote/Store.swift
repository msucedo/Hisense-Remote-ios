// Tienda: la compra única "Versión completa" con StoreKit 2.
// No hay servidor: Apple firma cada transacción y StoreKit la verifica en el
// teléfono. Toda función de pago se condiciona con `store.isFull`.

import Foundation
import StoreKit

@MainActor
final class Store: ObservableObject {
    static let fullID = "com.mariosaucedo.HisenseRemote.full"

    @Published var isFull = false
    @Published var product: Product?     // nil hasta que la App Store responde
    @Published var busy = false
    @Published var loading = false       // pidiendo el producto (y su precio) a la App Store
    @Published var message: String?      // avisos para la hoja de compra
    @Published var showUpgrade = false   // abre la hoja de compra desde cualquier pantalla

    private var updates: Task<Void, Never>?

    // Al abrir: escucha compras que llegan "por fuera" (aprobación de
    // "Pedir permiso", otro dispositivo, reembolsos), carga el producto y revisa
    // si ya se compró. currentEntitlements funciona sin internet.
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refreshEntitlement()
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    // Si la App Store no conoce el producto (aún no existe en App Store Connect, o
    // no hay cuenta) no da error: devuelve una lista vacía. Hay que avisarlo.
    func loadProduct() async {
        loading = true
        defer { loading = false }
        do {
            product = try await Product.products(for: [Self.fullID]).first
            if product == nil { message = "La compra no está disponible por ahora. Intenta más tarde." }
        } catch {
            message = "No pude cargar la tienda: \(error.localizedDescription)"
        }
    }

    // Solo cuentan transacciones verificadas y sin reembolso.
    func refreshEntitlement() async {
        var full = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.fullID, t.revocationDate == nil { full = true }
        }
        isFull = full
    }

    func buy() async {
        if product == nil { message = nil; await loadProduct() }
        guard let product else { return }    // loadProduct ya dejó el aviso
        busy = true; message = nil
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let t)):
                await t.finish()
                await refreshEntitlement()
            case .success(.unverified):
                message = "No se pudo verificar la compra."
            case .pending:
                message = "Compra pendiente de aprobación."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "No se pudo completar la compra: \(error.localizedDescription)"
        }
    }

    // Apple exige un botón para restaurar: pide a la App Store las compras de la
    // cuenta (puede pedir la contraseña) y vuelve a revisar.
    func restore() async {
        busy = true; message = nil
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isFull { message = "No encontré compras de la versión completa en esta cuenta." }
        } catch {
            message = "No se pudo restaurar: \(error.localizedDescription)"
        }
    }
}
