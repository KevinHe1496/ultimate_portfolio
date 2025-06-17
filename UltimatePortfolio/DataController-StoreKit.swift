//
//  DataController-StoreKit.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 26/5/25.
//

import Foundation
import StoreKit

extension DataController {
    /// ID del producto registrado en App Store para desbloquear la versión premium
    static let unlockPremiumProductID = "com.kevinhe.UltimatePortfolioTests.premiumUnlock"
    
    /// Almacena si el usuario ha comprado la versión premium usando UserDefaults
    var fullVersionUnlocked: Bool {
        get {
            defaults.bool(forKey: "fullVersionUnlocked") // Lee el valor guardado
        }
        set {
            defaults.set(newValue, forKey: "fullVersionUnlocked") // Guarda el nuevo valor
        }
    }
    
    /// Monitorea transacciones actuales y futuras para verificar compras y revocaciones
    func monitorTransactions() async {
        // Verifica compras previas al iniciar la app
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                await finalize(transaction) // Marca como finalizada si está verificada
            }
        }
        
        // Escucha nuevas transacciones en tiempo real (compra o revocación)
        for await update in Transaction.updates {
            if let transaction = try? update.payloadValue {
                await finalize(transaction) // Finaliza y actualiza el estado premium
            }
        }
    }
    #if !os(visionOS)
    /// Realiza la compra de un producto usando StoreKit 2
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase() // Inicia el proceso de compra
        
        if case let .success(validation) = result {
            try await finalize(validation.payloadValue) // Verifica y finaliza si fue exitosa
        }
    }
    #endif
    /// maneja las transacciones de forma segura, desbloquea el contenido correctamente y gestiona los reembolsos, todo en un solo lugar.
    @MainActor
    func finalize(_ transaction: Transaction) async {
        if transaction.productID == Self.unlockPremiumProductID {
            objectWillChange.send() // Notifica a SwiftUI que hubo un cambio
            fullVersionUnlocked = transaction.revocationDate == nil // Activa premium si no fue revocada
            await transaction.finish() // Marca la transacción como procesada
        }
    }
    
    @MainActor
    func loadProducts() async throws {
        guard products.isEmpty else { return }
        
        try await Task.sleep(for: .seconds(0.2))
        products = try  await Product.products(for: [Self.unlockPremiumProductID])
    }
}
