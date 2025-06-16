//
//  DataController.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 20/3/25.
//
import StoreKit
import CoreData
import SwiftUI
import WidgetKit

enum SortType: String {
    case dateCreated = "creationDate"
    case dateModified = "modificationDate"
}

enum Status {
    case all, open, closed
}

// Esta clase administra la carga y gestión de datos usando Core Data y CloudKit.

/// An environment singleton responsible for managing our Core Data stack, including handling saving,
/// counting fetch request, tracking orgers, and dealing with sample data.
class DataController: ObservableObject {
    
    /// The lone CloudKit container used to sotre all our data.
    let container: NSPersistentCloudKitContainer
    
    var spotlightDelegate: NSCoreDataCoreSpotlightDelegate?
    
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
    
    private var storeTask: Task<Void, Never>?
    // Task no devuelve nada, pero puede lanzar error y es opcional porque inicialmente no tendra nada
    private var saveTask: Task<Void, Error>?
    
    ///The UserDetaults suite where we're saving user data.
    let defaults: UserDefaults
    
    /// The StoreKit products we've loaded for the store.
    @Published var products = [Product]()
    
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
    
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "Main", withExtension: "momd") else {
            fatalError("Failed to locate model file.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load model file.")
        }
        
        return managedObjectModel
    }()
    
    /// Initializes a data controller, either in memory (for testing use such as previewing),
    /// or on permanent storage (for use in regular app runs.)
    ///
    /// Defaults to permanent storage.
    /// - Parameter inMemory: Whether to sotre this data in temporary memory or ot
    /// - Parameter defaults: The UserDefaults suite where user data should be stored.
    init(inMemory: Bool = false, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Se crea un contenedor persistente llamado "Main"
        container = NSPersistentCloudKitContainer(name: "Main", managedObjectModel: Self.model)
        
        storeTask = Task {
            await monitorTransactions()
        }
        
        // For testing and previewing purposes, we create a
        // temporary, in-memory database by writing to /dev/null
        // so our data is destroyed after the app finishes running.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        } else {
            let groupID = "group.com.ravecodesolutions.upa"
            
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
                container.persistentStoreDescriptions.first?.url = url.appending(path: "Main.sqlite")
            }
        }
        // habilita que core data realice el trabajo por nosotros
        container.viewContext.automaticallyMergesChangesFromParent = true
        /*
         ¿qué sucedería si modificáramos la misma propiedad en dos dispositivos diferentes? En ese caso, debemos decidir cuál es la correcta, por lo que la política de fusión que usaremos se llama ".mergeByPropertyObjectTrump". Esto significa que queremos que Core Data compare cada propiedad individualmente, pero si hay un conflicto, debería preferir lo que esté actualmente en memoria.
         */
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        
        // Make sure that we watch iCloud for all changes to make
        // absolutely sure we keep our local UI in sync when a
        // remore change happens.
        container.persistentStoreDescriptions.first?
            .setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
        
        container.persistentStoreDescriptions.first?
            .setOption(
                true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey
            )
        
        NotificationCenter.default
            .addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator,
                queue: .main,
                using: remoteStoreChange
            )
        
        // Carga los almacenes persistentes y maneja errores si ocurren
        container.loadPersistentStores {
            [weak self] _,
            error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
            
            if let description = self?.container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                
                if let coordinator = self?.container.persistentStoreCoordinator {
                    self?.spotlightDelegate = NSCoreDataCoreSpotlightDelegate(
                        forStoreWith: description,
                        coordinator: coordinator
                    )
                    
                    self?.spotlightDelegate?.startSpotlightIndexing()
                }
            }
            
            
            #if DEBUG
            if CommandLine.arguments.contains("enable-testing") {
                self?.deleteAll()
                #if os(iOS)
                UIView.setAnimationsEnabled(false)
                #endif
            }
            #endif
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
        for tagCounter in 1...5 {
            let tag = Tag(context: viewContext)
            tag.id = UUID() // Se asigna un identificador único
            tag.name = "Tag \(tagCounter)" // Se le da un nombre identificador
            
            // Cada etiqueta tiene 10 problemas (Issues) asociados
            for issueCounter in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(tagCounter)-\(issueCounter)" // Título del problema
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
    
    
    /// Saves our Core Data context if there are change. This silently ignores
    /// any errors caused by saving, nut this should be fine because
    /// all our attributes are optional.
    func save() {
        saveTask?.cancel()
        
        // Verifica si hay cambios en el contexto antes de intentar guardarlos
        if container.viewContext.hasChanges {
            // Intenta guardar los cambios, ignorando posibles errores con `try?`
            try? container.viewContext.save()
            WidgetCenter.shared.reloadAllTimelines()
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
        
        
        //⚠️ IMPORTANT: When performing a batch delete we need to make sure we read the result back
        // then merge all the changes from that result back into our live view context
        // so that the tow stay in sync.
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
    
    
    /// Runs a fetch request with various predicates thath filter the user's issues based on
    /// tag, title, and conten text, search tokens, priority, and completion status.
    /// - Returns: An array of all matching issues.
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
            let combinedPredicate = NSCompoundPredicate(
                orPredicateWithSubpredicates: [
                    titlePredicate,
                    contentPredicate
                ]
            )
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
    func newTag() -> Bool {
        var shouldCreate = fullVersionUnlocked
        
        if shouldCreate == false {
            shouldCreate = count(for: Tag.fetchRequest()) < 3
        }
        
        guard shouldCreate else {
            return false
        }
        
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = NSLocalizedString("New tag", comment: "Create a new tag")
        save()
        
        return true
    }
    
    /// agregamos nuevo issue
    func newIssue() {
        let issue = Issue(context: container.viewContext)
        issue.title = NSLocalizedString("New issue", comment: "Create a new issue")
        issue.creationDate = .now
        issue.priority = 1
        
        // If we are currently browing a user-created tag, immediately
        // add this new issue to the tag otherwise it won't appear in
        // the list of issues they see.
        if let tag = selectedFilter?.tag {
            issue.addToTags(tag)
        }
        
        save()
        
        selectedIssue = issue
    }
    
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    

    func issue(with uniqueIdentifier: String) -> Issue? {
        guard let url = URL(string: uniqueIdentifier) else {
            return nil
        }
        
        guard let id = container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {
            return nil
        }
        
        return try? container.viewContext.existingObject(with: id) as? Issue
    }
    
    func fetchRequestForTopIssues(count: Int) -> NSFetchRequest<Issue> {
        let request = Issue.fetchRequest()
        request.predicate = NSPredicate(format: "completed = false")
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Issue.priority, ascending: false)
        ]
        
        request.fetchLimit = count
        return request
    }
    
    func results<T: NSManagedObject>(for fetchRequest: NSFetchRequest<T>) -> [T] {
        return (try? container.viewContext.fetch(fetchRequest)) ?? []
    }
}
