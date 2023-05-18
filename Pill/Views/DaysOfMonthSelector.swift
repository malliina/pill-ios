import Foundation
import SwiftUI

struct DayOfMonthSelection {
    let day: Int
    var isSelected: Bool
}

struct DayOfMonthSelections {
    let selections: [DayOfMonthSelection]
}

struct DaysOfMonthSelector: View {
    @Binding var monthDays: [DayOfMonthSelection]

    func forall(selected: Bool) {
        (0..<monthDays.count).forEach { i in
            monthDays[i].isSelected = selected
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
                ForEach(monthDays.indices, id: \.self) { index in
                    HStack {
                        Button(action: {
                            monthDays[index].isSelected = !monthDays[index].isSelected
                        }) {
                            HStack {
                                Text("\(monthDays[index].day)").foregroundColor(.primary)
                                Spacer()
                                if monthDays[index].isSelected {
                                    Image(systemName: "checkmark").foregroundColor(.primary)
                                }
                            }
                        }.buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }.navigationTitle("Select days")
    }
}

struct DaysOfMonthSelector_Previews: PreviewProvider {
    static let previewDays = (1...31).map { DayOfMonthSelection(day: $0, isSelected: false) }
    static var previews: some View {
        Group {
            DaysOfMonthSelector(monthDays: .constant(previewDays))
        }
    }
}
