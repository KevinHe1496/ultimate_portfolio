

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedIssue) {
            ForEach(viewModel.dataController.issuesForSelectedFilter()) { issue in
                IssueRow(issue: issue)
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("Issues")
        .searchable(
            text: $viewModel.filterText,
            tokens: $viewModel.filterTokens,
            suggestedTokens: .constant(
                viewModel.suggestedFilterTokens
            ),
            prompt: "Filter issues, or type # to add tags"
        ) { tag in
            Text(tag.tagName)
        }
        .toolbar{
            ContentViewToolbar()
        }
    }
    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}

#Preview {
    ContentView(dataController: .preview)
}
