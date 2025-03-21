//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 20/3/25.
//

import CoreData

// Esta clase administra la carga y gestión de datos usando Core Data y CloudKit.
class DataController: ObservableObject {
    
    // Contenedor que maneja el almacenamiento persistente con CloudKit
    let container: NSPersistentCloudKitContainer
    
    @Published var selectedFilter: Filter? = Filter.all
    
    // Propiedad estática para proporcionar un DataController con datos de prueba
    static var preview: DataController = {
        // Se crea una instancia de DataController en modo memoria (sin almacenamiento persistente)
        let dataController = DataController(inMemory: true)
        
        // Se generan datos de muestra para poblar la base de datos en memoria
        dataController.createSampleData()
        
        // Se devuelve la instancia preconfigurada de DataController
        return dataController
    }()

    
    // Inicializador que configura el contenedor de Core Data
    init(inMemory: Bool = false) {
        // Se crea un contenedor persistente llamado "Main"
        container = NSPersistentCloudKitContainer(name: "Main")
        
        // Si la opción inMemory es true, Core Data guardará los datos solo en memoria (RAM) y no en el disco. Esto significa que los datos se borrarán cuando cierres la app.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        // Carga los almacenes persistentes y maneja errores si ocurren
        container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }
    
    // Método que genera datos de ejemplo en la base de datos
    func createSampleData() {
        let viewContext = container.viewContext // Contexto de vista de Core Data
        
        // Se crean 5 etiquetas (Tags)
        for i in 1...5 {
            let tag = Tag(context: viewContext)
            tag.id = UUID() // Se asigna un identificador único
            tag.name = "Tag \(i)" // Se le da un nombre identificador
            
            // Cada etiqueta tiene 10 problemas (Issues) asociados
            for j in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(i)-\(j)" // Título del problema
                issue.content = "Description goes here" // Descripción ficticia
                issue.creationDate = .now // Fecha de creación actual
                issue.completed = Bool.random() // Se marca como completado o no de manera aleatoria
                issue.priority = Int16.random(in: 0...2) // Se asigna una prioridad aleatoria (0, 1 o 2)
                
                // Se asocia el problema a la etiqueta
                tag.addToIssues(issue)
            }
        }
        
        // Se intenta guardar los datos en el contexto de Core Data
        try? viewContext.save()
    }
    
    // Método para guardar cambios en la base de datos
    func save() {
        // Verifica si hay cambios en el contexto antes de intentar guardarlos
        if container.viewContext.hasChanges {
            // Intenta guardar los cambios, ignorando posibles errores con `try?`
            try? container.viewContext.save()
        }
    }

    // Método para eliminar un objeto de Core Data
    func delete(_ object: NSManagedObject) {
        // Notifica a los observadores que el objeto cambiará (útil para SwiftUI)
        objectWillChange.send()
        
        // Se elimina el objeto del contexto de Core Data
        container.viewContext.delete(object)
        
        // Guarda los cambios después de eliminar el objeto
        save()
    }

    // Método privado para realizar una eliminación masiva en Core Data
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        // Se crea una solicitud de eliminación en lote basada en la consulta proporcionada
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // Se configura la solicitud para devolver los identificadores de los objetos eliminados
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        // Se ejecuta la eliminación en lote dentro del contexto de Core Data
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            // Se extraen los identificadores de los objetos eliminados
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            
            // Se notifican los cambios al contexto de Core Data para mantener la consistencia
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }

    // Método para eliminar todos los datos de la base de datos
    func deleteAll() {
        // Se crea una solicitud para eliminar todas las entidades "Tag"
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(request1) // Se llama al método de eliminación en lote
        
        // Se crea una solicitud para eliminar todas las entidades "Issue"
        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        delete(request2) // Se llama nuevamente al método de eliminación en lote
        
        // Guarda los cambios para confirmar la eliminación
        save()
    }

}
