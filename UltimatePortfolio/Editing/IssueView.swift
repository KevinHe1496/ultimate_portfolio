//
//  IssueView.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 25/3/25.
//

import SwiftUI

struct IssueView: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
    
    @State private var showingNotificationsError = false
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    TextField("Title", text: $issue.issueTitle, prompt: Text("Enter the issue title here"))
                        .font(.title)
                        .labelsHidden()
                    
                    Text("**Modified:** \(issue.issueModificationDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.secondary)
                    
                    Text("**Status:** \(issue.issueStatus)")
                        .foregroundStyle(.secondary)
                }
                
                Picker("Priority", selection: $issue.priority) {
                    Text("Low").tag(Int16(0))
                    Text("Medium").tag(Int16(1))
                    Text("High").tag(Int16(2))
                }
                
                TagsMenuView(issue: issue)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("Basic Information")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    TextField(
                        "Decription",
                        text: $issue.issueContent,
                        prompt: Text(
                            "Enter the issue description here"),
                        axis: .vertical
                    )
                    .labelsHidden()
                }
            }
            
            Section("Reminders") {
                Toggle("Show reminders", isOn: $issue.reminderEnabled.animation())
                
                if issue.reminderEnabled {
                    DatePicker(
                        "Reminder time",
                        selection: $issue.issueReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
        }
        .formStyle(.grouped)
        // si eliminamos el problema seleccionado, ya no podran realizar cambios en la vista.
        .disabled(issue.isDeleted)
        
        // detecta los cambios recibidos
        .onReceive(issue.objectWillChange) { _ in
            dataController.queueSave()
        }
        .onSubmit(dataController.save)
        .toolbar {
            IssueViewToolbar(issue: issue)
        }
        .alert("Oops!", isPresented: $showingNotificationsError) {
            #if os(macOS)
            SettingsLink {
                Text("Check Settings")
            }
            #elseif os(iOS)
            Button("Check Settings", action: showAppSettings)
            #endif
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("There was a problem setting your notification. Please check you have notifications enabled.")
        }
        .onChange(of: issue.reminderEnabled) { oldValue, newValue in
            updateReminder()
        }
        .onChange(of: issue.reminderTime) { oldValue, newValue in
            updateReminder()
        }
    }
    #if os(iOS)
    func showAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        
        openURL(settingsURL)
    }
    #endif
    
    func updateReminder() {
        dataController.removeReminders(for: issue)
        
        Task { @MainActor in
            if issue.reminderEnabled {
                let success = await dataController.addReminder(for: issue)
                
                if success == false {
                    issue.reminderEnabled = false
                    showingNotificationsError = true
                }
            }
        }
    }
}

#Preview {
    IssueView(issue: .example)
}
