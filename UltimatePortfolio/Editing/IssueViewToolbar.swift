//
//  IssueViewToolbar.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 4/4/25.
//
#if canImport(CoreHaptics)
import CoreHaptics
#endif
import SwiftUI

struct IssueViewToolbar: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
#if canImport(CoreHaptics)
    @State private var engine = try? CHHapticEngine()
    #endif
    
    var openCloseButtonText: LocalizedStringKey {
        issue.completed ? "Re-open Issue" : "Close Issue"
    }
    
    var body: some View {
#if !os(watchOS)
        Menu {
            Button("Copy Issue Title", systemImage: "doc.on.doc", action: copyToClipboard)
            
            Button(action: toggleCompleted) {
                Label(openCloseButtonText, systemImage: "bubble.left.and.exclamationmark.bubble.right")
            }
//            .sensoryFeedback(trigger: issue.completed) { oldValue, newValue in
//                if newValue {
//                    .success
//                } else {
//                    nil
//                }
//            }
            Divider()
            Section("Tags") {
                TagsMenuView(issue: issue)
            }
            
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
        }
        #endif
    }
    func toggleCompleted() {
        issue.completed.toggle()
        dataController.save()
#if canImport(CoreHaptics)
        if issue.completed {
            do {
                try engine?.start()
                
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)

                let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
                let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1, value: 0)
                // use that curve to control the haptic strength
                let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [start, end], relativeTime: 0)
                
                let event1 = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )
                // create a continuous haptic event starting immediately and lasting one second
                let event2 = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [sharpness, intensity],
                    relativeTime: 0.125,
                    duration: 1
                )
                
                let pattern = try CHHapticPattern(events: [event1, event2], parameterCurves: [parameter])
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {
                
            }
        }
        #endif
    }
    
    func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = issue.title
        #elseif os(macOS)
        NSPasteboard.general.prepareForNewContents()
        NSPasteboard.general.setString(issue.issueTitle, forType: .string)
        #endif
    }
}

#Preview {
    IssueViewToolbar(issue: Issue.example)
        .environmentObject(DataController(inMemory: true))
}
