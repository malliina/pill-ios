//
//  DaysOfMonthSelector.swift
//  Pill
//
//  Created by Michael Skogberg on 17.10.2021.
//

import Foundation
import SwiftUI

struct DayOfMonthSelection {
    let day: Int
    var isSelected: Bool
}

struct DaysOfMonthSelector: View {
    @Binding var monthDays: [DayOfMonthSelection]

    var body: some View {
        List {
            ForEach(0..<monthDays.count) { index in
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
