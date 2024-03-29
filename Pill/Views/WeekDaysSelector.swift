import Foundation
import SwiftUI

struct WeekDaySelection {
  let day: WeekDay
  var isSelected: Bool
}

struct WeekDaysSelector: View {
  @Binding var weekDays: [WeekDaySelection]

  func forall(selected: Bool) {
    (0..<weekDays.count).forEach { i in
      weekDays[i].isSelected = selected
    }
  }

  var body: some View {
    VStack {
      HStack {
        Spacer()
        Button("All") {
          forall(selected: true)
        }
        Spacer()
        Button("None") {
          forall(selected: false)
        }
        Spacer()
      }.padding()
      List {
        ForEach(weekDays.indices, id: \.self) { index in
          HStack {
            Button {
              weekDays[index].isSelected = !weekDays[index].isSelected
            } label: {
              HStack {
                Text(weekDays[index].day.rawValue).foregroundColor(.primary)
                Spacer()
                if weekDays[index].isSelected {
                  Image(systemName: "checkmark").foregroundColor(.primary)
                }
              }
            }.buttonStyle(BorderlessButtonStyle())
          }
        }
      }
    }.navigationTitle("Select weekdays")
  }
}

struct WeekDaysSelectorPreviews: PreviewProvider {
  static let allSelected = WeekDay.allCases.map { weekDay in
    WeekDaySelection(day: weekDay, isSelected: true)
  }
  static var previews: some View {
    Group {
      WeekDaysSelector(weekDays: .constant(allSelected))
    }
  }
}
