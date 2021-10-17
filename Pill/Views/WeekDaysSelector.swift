//
//  WeekDaysSelector.swift
//  Pill
//
//  Created by Michael Skogberg on 17.10.2021.
//

import Foundation
import SwiftUI

struct WeekDaySelection {
    let day: WeekDay
    var isSelected: Bool
}

struct WeekDaysSelector: View {
    @Binding var weekDays: [WeekDaySelection]

    var body: some View {
        List {
            ForEach(0..<weekDays.count) { index in
                HStack {
                    Button(action: {
                        weekDays[index].isSelected = !weekDays[index].isSelected
                    }) {
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
    }
}

struct WeekDaysSelector_Previews: PreviewProvider {
    static let allSelected = WeekDay.allCases.map { weekDay in
        WeekDaySelection(day: weekDay, isSelected: true)
    }
    static var previews: some View {
        Group {
            WeekDaysSelector(weekDays: .constant(allSelected))
        }
    }
}
