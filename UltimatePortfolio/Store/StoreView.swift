//
//  StoreView.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 26/5/25.
//
import StoreKit
import SwiftUI

struct StoreView: View {
    @EnvironmentObject var dataController: DataController // Accede al controlador de datos compartido
    @Environment(\.dismiss) var dismiss // Cierra la vista actual cuando se llama
    @State private var products = [Product]() // Almacena los productos disponibles para compra

    var body: some View {
        NavigationStack {
            if let product = products.first {
                VStack(alignment: .leading, spacing: 20) {
                    Text(product.displayName) // Nombre del producto
                        .font(.title)

                    Text(product.description) // Descripción del producto
                        .font(.body)

                    Button("Buy Now") {
                        purchase(product) // Inicia el proceso de compra del producto
                    }
                    .buttonStyle(.borderedProminent) // Estilo destacado del botón
                }
                .padding() // Agrega espacio alrededor del contenido
                .navigationTitle("Tienda") // Título de la navegación
            } else {
                ProgressView("Cargando producto...") // Indicador mientras se cargan los productos
            }
        }
        .onChange(of: dataController.fullVersionUnlocked) { _, newValue in
            checkForPurchase() // Cierra la vista si la compra fue exitosa
        }
        .task {
            await load() // Carga los productos al aparecer la vista
        }
    }

    /// Cierra la vista si el usuario ya tiene la versión premium activa
    func checkForPurchase() {
        if dataController.fullVersionUnlocked {
            dismiss()
        }
    }

    /// Inicia el proceso de compra del producto con StoreKit
    func purchase(_ product: Product) {
        Task { @MainActor in
            do {
                try await dataController.purchase(product) // Compra y valida el producto
            } catch {
                print("Compra falló: \(error.localizedDescription)") // Muestra errores si ocurren
            }
        }
    }

    /// Carga los productos disponibles desde App Store Connect
    func load() async {
        do {
            products = try await Product.products(for: [DataController.unlockPremiumProductID]) // Recupera el producto por ID
        } catch {
            print("Error cargando productos: \(error.localizedDescription)") // Maneja errores de carga
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(DataController(inMemory: true)) // Previsualiza la vista con datos en memoria
}
