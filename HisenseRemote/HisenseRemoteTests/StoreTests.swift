// Prueba la compra de la versión completa contra la tienda simulada de Xcode
// (Products.storekit): no cobra nada ni necesita App Store Connect.

import Foundation
import StoreKitTest
import Testing
@testable import HisenseRemote

@MainActor
struct StoreTests {
    // Products.storekit está junto al .xcodeproj, un nivel arriba de esta carpeta.
    private let config = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Products.storekit")

    @Test func compraDesbloqueaYReembolsoBloquea() async throws {
        // En iOS 26 la app necesita get-task-allow (HisenseRemote/Debug.entitlements); sin él,
        // SKTestSession falla (SKInternalErrorDomain 3), la compra se va a la tienda real y se cuelga.
        let session = try SKTestSession(contentsOf: config)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true

        let store = Store()
        await store.loadProduct()
        #expect(store.product?.id == Store.fullID)
        #expect(store.product?.displayPrice.contains("29") == true,
                "precio: \(store.product?.displayPrice ?? "nil")")

        await store.refreshEntitlement()
        #expect(store.isFull == false)

        await store.buy()
        #expect(store.isFull == true)

        // Un reembolso debe volver a bloquearla. StoreKit lo aplica de forma
        // asíncrona, así que se revisa unas cuantas veces.
        let t = try #require(session.allTransactions().first)
        try session.refundTransaction(identifier: t.identifier)
        for _ in 0..<20 where store.isFull {
            try await Task.sleep(nanoseconds: 100_000_000)
            await store.refreshEntitlement()
        }
        #expect(store.isFull == false)
    }
}
