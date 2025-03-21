//
//  Filter.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 21/3/25.
//

import Foundation 

/// Estructura que representa un filtro para las incidencias (Issues).
/// Implementa Identifiable y Hashable para que pueda ser utilizada en listas y comparaciones.
struct Filter: Identifiable, Hashable {
    var id: UUID // Identificador único para cada filtro.
    var name: String // Nombre del filtro (ej. "Todos los Issues", "Recientes").
    var icon: String // Nombre del icono asociado al filtro (usado en la UI).
    var minModificationDate = Date.distantPast // Fecha mínima de modificación para filtrar datos.
    var tag: Tag? // Opcional: Permite asociar un filtro a una categoría (Tag).

    /// Filtro predefinido que representa "Todos los Issues".
    static var all = Filter(id: UUID(), name: "All Issues", icon: "tray")

    /// Filtro predefinido que muestra los issues recientes (últimos 7 días).
    static var recent = Filter(
        id: UUID(),
        name: "Recent issues",
        icon: "clock",
        minModificationDate: .now.addingTimeInterval(86400 * -7) // 7 días atrás
    )

    /// Implementación del protocolo Hashable para poder usar la estructura en conjuntos y diccionarios.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Usa el ID para calcular el hash único.
    }

    /// Implementación del operador de igualdad para comparar dos filtros.
    static func ==(lhs: Filter, rhs: Filter) -> Bool {
        lhs.id == rhs.id // Dos filtros son iguales si tienen el mismo ID.
    }
}
