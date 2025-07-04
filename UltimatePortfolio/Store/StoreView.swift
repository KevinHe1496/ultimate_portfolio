//
//  StoreView.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 26/5/25.
//
import StoreKit
import SwiftUI

struct StoreView: View {
    
    enum LoadState {
        case loading, loaded, error
    }

    @Environment(\.purchase) var purchaseAction

    @EnvironmentObject var dataController: DataController // Accede al controlador de datos compartido
    @Environment(\.dismiss) var dismiss // Cierra la vista actual cuando se llama
    @State private var loadState = LoadState.loading
    @State private var showingPurchaseError = false
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Image(decorative: "unlock")
                        .resizable()
                        .scaledToFit()
                    
                    Text("Upgrade Today!")
                        .font(.title.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                    
                    Text("Get the most out of the app")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.blue.gradient)
                ScrollView {
                    VStack {
                        switch loadState {
                        case .loading:
                            Text("Fetching offers...")
                                .font(.title2.bold())
                                .padding(.top, 50)
                            
                            ProgressView()
                                .controlSize(.large)
                            
                        case .loaded:
                            ForEach(dataController.products) { product in
                                Button {
                                    purchase(product)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(product.displayName)
                                                .font(.title2.bold())
                                            
                                            Text(product.description)
                                        }
                                        Spacer()
                                        
                                        Text(product.displayPrice)
                                            .font(.title)
                                            .fontDesign(.rounded)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(.gray.opacity(0.2), in: .rect(cornerRadius: 20))
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                            
                        case .error:
                            Text("Sorry, there was an error loading our store.")
                                .padding(.top, 50)
                            Button("Try again") {
                                Task {
                                    await load()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(20)
                }
                
                Button("Restore Purchases", action: restore)
                
                Button("Cancel") {
                    dismiss()
                }
                .padding(.top, 20)
            }
        }
        .alert("In-app purchases are disabled", isPresented: $showingPurchaseError) {
        } message: {
            Text("""
                     You can't purchase the premium unlock becuase in-app purchases are disabled on this device.
                     
                     Please ask whomever manages your device for assitance.
                     
                     """)
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
        guard AppStore.canMakePayments else {
            showingPurchaseError.toggle()
            return
        }
        
        Task { @MainActor in
            
            let result = try await purchaseAction(product)
            
            if case let .success(validation) = result {
                try await dataController.finalize(validation.payloadValue) // Verifica y finaliza si fue exitosa
            }
        }
    }
    
    /// Carga los productos disponibles desde App Store Connect
    func load() async {
        loadState = .loading
        do {
            try await dataController.loadProducts()
            
            if dataController.products.isEmpty {
                loadState = .error
            } else {
                loadState = .loaded
            }
        } catch {
            loadState = .error
        }
    }
    
    func restore() {
        Task {
            try await AppStore.sync()
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(DataController(inMemory: true)) // Previsualiza la vista con datos en memoria
}
