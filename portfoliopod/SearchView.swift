import SwiftUI

struct SearchView: View {
  @ObservedObject var contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @ObservedObject var physics: ClickWheelPhysics

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("[ SEARCHING ALL SYSTEMS ... ]")
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .foregroundColor(SettingsStore.shared.theme.accentColor)
        .padding(.bottom, 10)

      let nodes = contentStore.allNodes.sorted(by: { $0.title < $1.title })

      VStack(alignment: .leading, spacing: 6) {
        ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
          HStack {
            Text(
              physics.selectionIndex == index
                ? ">> \(node.title.uppercased())" : "   \(node.title.uppercased())"
            )
            .font(
              .system(
                size: 12, weight: physics.selectionIndex == index ? .bold : .medium,
                design: .monospaced)
            )
            .foregroundColor(physics.selectionIndex == index ? .white : .black)

            Spacer()

            Text(node.contentType.rawValue.capitalized)
              .font(.system(size: 8, design: .monospaced))
              .foregroundColor(.gray)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(
            physics.selectionIndex == index ? SettingsStore.shared.theme.accentColor : Color.clear)
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .onAppear {
      physics.numberOfItems = contentStore.allNodes.count
    }
  }
}
