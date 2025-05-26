//
//  DataController-Notifications.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 23/5/25.
//

import Foundation
import UserNotifications

extension DataController {
    /// Agrega un recordatorio local para una issue, pidiendo permisos si es necesario
    func addReminder(for issue: Issue) async -> Bool {
        do {
            let center = UNUserNotificationCenter.current() // Centro de notificaciones del sistema
            let settings = await center.notificationSettings() // Configuración actual del usuario
            
            switch settings.authorizationStatus {
            case .notDetermined:
                let success = try await requestNotifications() // Solicita permiso por primera vez
                
                if success {
                    try await placeReminders(for: issue) // Programa la notificación si acepta
                } else {
                    return false // Usuario negó el permiso
                }
                
            case .authorized:
                try await placeReminders(for: issue) // Usuario ya dio permiso, se programa directamente
                
            default:
                return false // Usuario denegó o está restringido (por control parental, por ejemplo)
            }
            
            return true // Recordatorio programado correctamente
        } catch {
            return false // Maneja errores silenciosamente
        }
    }
    
    /// Elimina recordatorios pendientes asociados a una issue específica
    func removeReminders(for issue: Issue) {
        let center = UNUserNotificationCenter.current()
        let id = issue.objectID.uriRepresentation().absoluteString // ID único basado en Core Data
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    /// Solicita autorización para enviar notificaciones al usuario
    private func requestNotifications() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound]) // Solo alerta y sonido
    }
    
    /// Programa una notificación local para una issue específica
    private func placeReminders(for issue: Issue) async throws {
        let content = UNMutableNotificationContent()
        content.title = issue.issueTitle // Título de la notificación desde el título de la issue
        content.sound = .default // Sonido predeterminado del sistema
        
        if let issueContent = issue.content {
            content.subtitle = issueContent // Usa el contenido de la issue como subtítulo si existe
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // Dispara en 5 segundos (pruebas)
        
        let id = issue.objectID.uriRepresentation().absoluteString // ID único para esta notificación
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        return try await UNUserNotificationCenter.current().add(request) // Añade la notificación al sistema
    }
}
