//
//  CoverFlowView.swift
//  portfoliopod
//
//  3D perspective carousel for portfolio items
//

import SwiftUI

struct CoverFlowView: View {
  let items: [MenuNode]
  @Binding var selectedIndex: Int

  var body: some View {
    GeometryReader { geometry in
      let center = geometry.size.width / 2

      ZStack {
        ForEach(0..<items.count, id: \.self) { index in
          CoverFlowItem(
            item: items[index],
            index: index,
            selectedIndex: selectedIndex,
            center: center
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color.black)
  }
}

struct CoverFlowItem: View {
  let item: MenuNode
  let index: Int
  let selectedIndex: Int
  let center: CGFloat

  var body: some View {
    let diff = CGFloat(index - selectedIndex)
    let isSelected = index == selectedIndex

    ZStack {
      // Placeholder "Album" Art (Brutalist style)
      Rectangle()
        .fill(Color.black)
        .overlay(
          Rectangle()
            .stroke(isSelected ? Color.red : Color.gray, lineWidth: isSelected ? 2 : 1)
        )
        .overlay(
          VStack(spacing: 12) {
            Image(systemName: "photo.fill")
              .font(.system(size: 30))
              .foregroundColor(isSelected ? .red : .gray)

            Text(item.title.uppercased())
              .font(.system(size: 8, weight: .bold, design: .monospaced))
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 8)
          }
        )
    }
    .frame(width: 140, height: 140)
    .rotation3DEffect(
      .degrees(isSelected ? 0 : (diff > 0 ? -60 : 60)),
      axis: (x: 0, y: 1, z: 0),
      perspective: 0.8
    )
    .offset(x: diff * (isSelected ? 0 : 40))
    .scaleEffect(isSelected ? 1.0 : 0.75)
    .zIndex(isSelected ? 100 : Double(10 - abs(diff)))
    .opacity(isSelected ? 1.0 : (abs(diff) > 2 ? 0 : 0.7))
    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedIndex)
  }
}
