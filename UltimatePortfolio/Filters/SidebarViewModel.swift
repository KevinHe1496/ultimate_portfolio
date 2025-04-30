//
//  SidebarViewModel.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 30/4/25.
//

import CoreData
import Foundation

extension SidebarView {
    /// ViewModel que gestiona la lógica de la barra lateral, incluyendo la obtención, edición y eliminación de etiquetas desde Core Data.
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        
        /// Controlador de datos que maneja Core Data en la app.
        var dataController: DataController
        
        /// Controlador que escucha cambios en las etiquetas almacenadas en Core Data.
        private let tagsController: NSFetchedResultsController<Tag>
        
        /// Lista de etiquetas obtenidas de Core Data.
        @Published var tags = [Tag]()
        
        /// Etiqueta seleccionada para renombrar.
        @Published var tagToRename: Tag?
        
        /// Bandera que indica si se está renombrando una etiqueta.
        @Published var renamingTag = false
        
        /// Nombre temporal usado para renombrar una etiqueta.
        @Published var TagName = ""
        
        /// Convierte cada etiqueta en un filtro reutilizable con nombre, ícono y su ID.
        var tagFilters: [Filter] {
            tags.map { tag in
                Filter(id: tag.tagID, name: tag.tagName, icon: "tag", tag: tag)
            }
        }
        
        /// Inicializa el ViewModel y realiza la primera carga de etiquetas desde Core Data.
        init(dataController: DataController) {
            self.dataController = dataController
            
            let request = Tag.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            tagsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            super.init()
            
            tagsController.delegate = self
            
            do {
                try tagsController.performFetch()
                tags = tagsController.fetchedObjects ?? []
            } catch {
                print("Failed to fetch tags")
            }
        }
        
        /// Se llama automáticamente cuando cambian los datos en Core Data; actualiza la lista de etiquetas.
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if let newTags = controller.fetchedObjects as? [Tag] {
                tags = newTags
            }
        }
        
        /// Elimina una o más etiquetas según los índices seleccionados.
        func delete(_ offsets: IndexSet) {
            for offset in offsets {
                let item = tags[offset]
                dataController.delete(item)
            }
        }
        
        /// Elimina una etiqueta a partir de un filtro seleccionado.
        func delete(_ filter: Filter) {
            guard let tag = filter.tag else { return }
            dataController.delete(tag)
            dataController.save()
        }
        
        /// Activa el modo de renombrado para una etiqueta seleccionada.
        func rename(_ filter: Filter) {
            tagToRename = filter.tag
            TagName = filter.name
            renamingTag = true
        }
        
        /// Completa el proceso de renombrado y guarda el nuevo nombre en Core Data.
        func completeRename() {
            tagToRename?.name = TagName
            dataController.save()
        }
    }
}
