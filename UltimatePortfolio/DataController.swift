//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 20/3/25.
//

import CoreData

enum SortType: String {
    case dateCreated = "creationDate"
    case dateModified = "modificationDate"
}

enum Status {
    case all, open, closed
}

// Esta clase administra la carga y gestión de datos usando Core Data y CloudKit.
class DataController: ObservableObject {
    
    // Contenedor que maneja el almacenamiento persistente con CloudKit
    let container: NSPersistentCloudKitContainer
    
    // inicializa con todos los issues
    @Published var selectedFilter: Filter? = Filter.all
    
    @Published var selectedIssue: Issue?
    
    @Published var filterText = ""
    @Published var filterTokens = [Tag]()
    
    @Published var filterEnabled = false
    @Published var filterPrority = -1
    @Published var filterStatus = Status.all
    @Published var sortType = SortType.dateCreated
    @Published var sortNewestFirst = true
    
    // Task no devuelve nada, pero puede lanzar error y es opcional porque inicialmente no tendra nada
    private var saveTask: Task<Void, Error>?
    
    // Propiedad estática para proporcionar un DataController con datos de prueba
    static var preview: DataController = {
        // Se crea una instancia de DataController en modo memoria (sin almacenamiento persistente)
        let dataController = DataController(inMemory: true)
        
        // Se generan datos de muestra para poblar la base de datos en memoria
        dataController.createSampleData()
        
        // Se devuelve la instancia preconfigurada de DataController
        return dataController
    }()
    
    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else {
            return []
        }
        
        let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
        let request = Tag.fetchRequest()
        
        if trimmedFilterText.isEmpty == false {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
        }
        
        return (try? container.viewContext.fetch(request).sorted()) ?? []
    }
    // Inicializador que configura el contenedor de Core Data
    init(inMemory: Bool = false) {
        // Se crea un contenedor persistente llamado "Main"
        container = NSPersistentCloudKitContainer(name: "Main")
        
        // Si la opción inMemory es true, Core Data guardará los datos solo en memoria (RAM) y no en el disco. Esto significa que los datos se borrarán cuando cierres la app.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        // habilita que core data realice el trabajo por nosotros
        container.viewContext.automaticallyMergesChangesFromParent = true
        /*
         ¿qué sucedería si modificáramos la misma propiedad en dos dispositivos diferentes? En ese caso, debemos decidir cuál es la correcta, por lo que la política de fusión que usaremos se llama ".mergeByPropertyObjectTrump". Esto significa que queremos que Core Data compare cada propiedad individualmente, pero si hay un conflicto, debería preferir lo que esté actualmente en memoria.
         */
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Le dice al sistema que llame a nuestro RemoteStoreChanged, cada vez que ocurra un cambio
        NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator, queue: .main, using: remoteStoreChange)
        
        // Carga los almacenes persistentes y maneja errores si ocurren
        container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }
    /// Le dice a coredata que queremos ser notificamos cuando el store haya cambiado
    func remoteStoreChange(_ notification: Notification) {
        objectWillChange.send()
    }
    
    /// Método que genera datos de ejemplo en la base de datos
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
    
    /// Método para guardar cambios en la base de datos
    func save() {
        saveTask?.cancel()
        
        // Verifica si hay cambios en el contexto antes de intentar guardarlos
        if container.viewContext.hasChanges {
            // Intenta guardar los cambios, ignorando posibles errores con `try?`
            try? container.viewContext.save()
        }
    }
    
    /// Metodo que guarda los cuambios depues de 3 segundos
    
    func queueSave() {
        // cancelamos la tarea si se produce otro cambio
        saveTask?.cancel()
        // guardamos la nueva tarea en SaveTask
        saveTask = Task { @MainActor in
            // suspendemos 3 segundos
            try await Task.sleep(for: .seconds(3))
            // guardamos
            save()
            
        }
    }
    
    /// Método para eliminar un objeto de Core Data
    func delete(_ object: NSManagedObject) {
        // Notifica a los observadores que el objeto cambiará (útil para SwiftUI)
        objectWillChange.send()
        
        // Se elimina el objeto del contexto de Core Data
        container.viewContext.delete(object)
        
        // Guarda los cambios después de eliminar el objeto
        save()
    }
    
    /// Método privado para realizar una eliminación masiva en Core Data
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
    
    /// Método para eliminar todos los datos de la base de datos
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
    
    /// Cargar internamente todas las etiquetas que puedan existir.
    /// Calcular qué etiquetas no están asignadas actualmente al problema.
    /// Ordena esas etiquetas y luego envíalas de vuelta.
    func missingTags(from issue: Issue) -> [Tag] {
        let request = Tag.fetchRequest()
        let allTags = (try? container.viewContext.fetch(request)) ?? []
        
        let allTagsSet = Set(allTags)
        let difference = allTagsSet.symmetricDifference(issue.issueTags)
        
        return difference.sorted()
    }
    
    func issuesForSelectedFilter() -> [Issue] {
        let filter = selectedFilter ?? .all
        var predicates = [NSPredicate]()
        
        
        if let tag = filter.tag {
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            // modificationDate Es el nombre del atributo que almacena una fecha
            // > Significa "mayor que", por lo que se filtrarán los objetos cuya modificationDate sea despues a una fecha dada.
            let datePredicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
            
        }
        
        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)
        
        if !trimmedFilterText.isEmpty {
            
            // title es el nombre del atributo que se quiere filtrar
            // CONTAINS Busca si el valor del atributo content contiene el texto indicado.
            // [c] Hace la búsqueda case insensitive (ignora mayúsculas y minúsculas).
            // %@ es un placeholder que será reemplazado por trimmedFilterText, que es el texto que se busca dentro de content
            let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
            let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
            
            // esto toma nuestro array de predicados y garantiza que todos coincidan para cada issue en la solicitud de búsqueda.
            let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
            predicates.append(combinedPredicate)
        }
        
        if filterTokens.isEmpty == false {
            for filterToken in filterTokens {
                let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
                predicates.append(tokenPredicate)
            }
        }
        
        if filterEnabled {
            if filterPrority >= 0 {
                // = %d indica que se comparará con un valor entero
                let priorityFilter = NSPredicate(format: "priority = %d", filterPrority)
                predicates.append(priorityFilter)
            }
        }
        
        if filterStatus != .all {
            let lookForClosed = filterStatus == .closed
            // = %@ es un marcador de posición para cualquier tipo de objeto (como Bool, String, NSNumber, etc.).
            let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
            predicates.append(statusFilter)
        }
        
        let request = Issue.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]
        let allIssues = (try? container.viewContext.fetch(request)) ?? []
        
        return allIssues
    }
    
    /// agregamos un nuevo tag
    func newTag() {
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = NSLocalizedString("New tag", comment: "Create a new tag")
        save()
    }
    
    /// agregamos nuevo issue
    func newIssue() {
        let issue = Issue(context: container.viewContext)
        issue.title = NSLocalizedString("New issue", comment: "Create a new issue")
        issue.creationDate = .now
        issue.priority = 1
        
        if let tag = selectedFilter?.tag {
            issue.addToTags(tag)
        }
        
        save()
        
        selectedIssue = issue
    }
    
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    
    /// Premios que ha ganamos segun los issues, closed, tags
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
        case "issues":
            // return true if they added a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            let awadCount = count(for: fetchRequest)
            return awadCount >= award.value
            
        case "closed":
            // returns true if they closed a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completed = true")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        case "tags":
            // return true if they created a certain number of tags
            let fetchRequest = Tag.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        default:
            // an unknown award criterion; this should never be allowed
            // fatalError("Unknown award criterion: \(award.criterion)")
            return false
        }
    }
    
}
