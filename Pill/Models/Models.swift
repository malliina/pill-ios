//
//  Models.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import Foundation

enum WeekDay: String, CaseIterable, Codable, Identifiable {
    case mon = "Monday"
    case tue = "Tuesday"
    case wed = "Wednesday"
    case thu = "Thursday"
    case fri = "Friday"
    case sat = "Saturday"
    case sun = "Sunday"
    var id: String { self.rawValue }
    var short: String {
        switch self {
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        case .sun: return "Sun"
        }
    }
}

struct Time: Codable {
    let hour: Int
    let minute: Int
    var minuteTwoDigits: String { minute < 10 ? "0\(minute)" : "\(minute)" }
    var describe: String { "\(hour):\(minuteTwoDigits)" }
    var today: Date {
        let cal = Calendar.current
        let now = Date()
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }
}

enum Interval: String, CaseIterable, Codable, Identifiable {
    case none
    case daily
//    case weekly
    case monthly
    
//    var all: [Interval] { [Interval.none, Interval.daily, Interval.weekly, Interval.monthly] }
//    var timed(at: Time): When {
//        switch self {
//        case .none: When.
//        case .daily: When.daily(at)
//        case .weekly: When.weekly(WeekDay.mon, at)
//        case .monthly: When.monthly(2, at)
//        }
//
//    }
    
    var id: String { self.rawValue }
}

enum HaltInterval: String, CaseIterable, Codable, Identifiable {
    case none
    case nthWeek
    case nthMonth
    var id: String { self.rawValue }
}

enum When: Codable {
    case once(Date), daily([WeekDay], Time), monthly([Int], Time)
    
    var interval: Interval {
        switch self {
        case .once(_): return .none
        case .daily(_, _): return .daily
        case .monthly(_, _): return .monthly
        }
    }
    var time: Time {
        switch self {
        case .once(let date): return date.time
        case .daily(_, let t): return t
        case .monthly(_, let t): return t
        }
    }
    var weekDays: [WeekDay]? {
        switch self {
        case .once(_): return nil
        case .daily(let days, _): return days
        case .monthly(_, _): return nil
        }
    }
    var monthDays: [Int]? {
        switch self {
        case .once(_): return nil
        case .daily(_, _): return nil
        case .monthly(let days, _): return days
        }
    }
}

struct NthSpec: Codable {
    let start: Date
    let nth: Int
}

enum Halt: Codable {
    case nthWeek(NthSpec), nthMonth(NthSpec)//, months([Int])
    
    var interval: HaltInterval {
        switch self {
        case .nthWeek(_): return .nthWeek
        case .nthMonth(_): return .nthMonth
//        case .months(_): return .monthly
        }
    }
    
    var nth: Int? {
        switch self {
        case .nthWeek(let spec): return spec.nth
        case .nthMonth(let spec): return spec.nth
//        default: return nil
        }
    }
    
    func isHalted(date: Date) -> Bool {
        switch self {
        case .nthWeek(let spec):
            let calendar = Calendar.current
            let from = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: spec.start) ?? spec.start
            let to = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let daysComponents = calendar.dateComponents([.day], from: from, to: to)
            let days = daysComponents.value(for: .day) ?? 0
            let remainder = ((days / 7) + 1) % spec.nth
//            print("Days \(days) weeks \(days / 7) r1 \(12 % 2) remainder \(remainder) from \(from) to \(to)")
            return remainder == 0
        case .nthMonth(let spec):
            let calendar = Calendar.current
            let from = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: spec.start) ?? spec.start
            let to = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let daysComponents = calendar.dateComponents([.month], from: from, to: to)
            let months = daysComponents.value(for: .month) ?? 0
            let remainder = (months + 1) % spec.nth
            return remainder == 0
//        default:
//            return false
        }
    }
}

extension Date {
    var time: Time {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: self)
        let minutes = cal.component(.minute, from: self)
        return Time(hour: hour, minute: minutes)
    }
    
    func at(time: Time) -> Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: self) ?? self
    }
}

struct MutableReminder {
//    static let empty: MutableReminder = Reminder(id: UUID().uuidString, enabled: true, name: "", when: When.daily(WeekDay.allCases, Time(hour: 8, minute: 15)), halt: nil, start: Date()).mutable
    static func create() -> MutableReminder {
        let reminder = Reminder(id: UUID().uuidString, enabled: true, name: "", when: When.once(Date().addingTimeInterval(300)), halt: nil, start: Date())
        return reminder.mutable
    }
    let log = LoggerFactory.shared.system(MutableReminder.self)
    let id: String
    var enabled: Bool
    var name: String
    var whenInterval: Interval
    var whenWeekDays: [WeekDaySelection]
    var whenDaysOfMonth: [DayOfMonthSelection]
    var timeAsDate: Date
    var haltInterval: HaltInterval
    var haltNth: Int
    var start: Date
    
    func upcoming(from: Date, limit: Int) -> [Date] {
        guard limit > 0 else { return [] }
        let cal = Calendar.current
        let time = timeAsDate.time
        switch whenInterval {
        case .none:
            let date = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from) ?? from
            let now = Date()
            return date > now ? [date] : []
        case .daily:
            let today = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from) ?? from
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? from
            // If equal, take next day, prob recursion
            let next = from < today ? today : tomorrow
            let range = 1..<limit
            let potentialDays = [next] + range.compactMap { i in
                cal.date(byAdding: .day, value: i, to: next)
            }
            let halt = asHalt()
            let batch = potentialDays.filter { date in
                !(halt?.isHalted(date: date) ?? false)
            }
            if let mostDistant = potentialDays.last, batch.count < limit {
                log.info("Recurse after batch \(batch.count) remaining \(limit-batch.count) from \(mostDistant)")
                return batch + upcoming(from: mostDistant, limit: limit - batch.count)
            } else {
                return batch
            }
        case .monthly:
            let startCandidate = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from) ?? from
            let now = Date()
            if now > startCandidate {
                guard let nextCandidate = cal.date(byAdding: .month, value: 1, to: startCandidate) else { return [] }
                return upcoming(from: nextCandidate, limit: limit)
            } else {
                let range = 0..<limit
                let potentialMonths = range.compactMap { i in
                    cal.date(byAdding: .month, value: i, to: startCandidate)
                }
                let halt = asHalt()
                let batch = potentialMonths.filter { date in
                    !(halt?.isHalted(date: date) ?? false)
                }
                if let mostDistant = potentialMonths.last, batch.count < limit, let nextFrom = cal.date(byAdding: .month, value: 1, to: mostDistant) {
                    log.info("Recurse after batch \(batch.count) remaining \(limit-batch.count) from \(mostDistant)")
                    return batch + upcoming(from: nextFrom, limit: limit - batch.count)
                } else {
                    return batch
                }
            }
        }
    }
    
    func asHalt() -> Halt? {
        switch haltInterval {
        case .none:
            return nil
        case .nthWeek:
            return Halt.nthWeek(NthSpec(start: start, nth: haltNth))
        case .nthMonth:
            return Halt.nthMonth(NthSpec(start: start, nth: haltNth))
        }
    }
    
    func asWhen() -> When {
        switch whenInterval {
        case .none:
            return .once(start.at(time: timeAsDate.time))
        case .daily:
            let days = whenWeekDays.filter({ day in day.isSelected }).map({ day in day.day })
            return When.daily(days, timeAsDate.time)
        case .monthly:
            let daysOfMonth = whenDaysOfMonth.filter({ dayOfMonth in
                dayOfMonth.isSelected
            }).map({ dayOfMonth in
                dayOfMonth.day
            })
            return When.monthly(daysOfMonth, timeAsDate.time)
        }
    }
    
    var immutable: Reminder {
        Reminder(id: id, enabled: enabled, name: name, when: asWhen(), halt: asHalt(), start: start)
    }
}

struct Reminder: Codable, Identifiable {
    let id: String
    let enabled: Bool
    let name: String
    let when: When
    let halt: Halt?
    let start: Date
    
    var mutable: MutableReminder {
        let enabledDays = when.weekDays ?? []
        let weekDays = WeekDay.allCases.map { weekDay in
            WeekDaySelection(day: weekDay, isSelected: enabledDays.contains(weekDay))
        }
        let enabledMonthDays = when.monthDays ?? []
        let monthDays = (1...31).map { day in
            DayOfMonthSelection(day: day, isSelected: enabledMonthDays.contains(day))
        }
        return MutableReminder(id: id, enabled: enabled, name: name, whenInterval: when.interval, whenWeekDays: weekDays, whenDaysOfMonth: monthDays, timeAsDate: when.time.today, haltInterval: halt?.interval ?? HaltInterval.none, haltNth: halt?.nth ?? 2, start: start) }
}

struct Reminders: Codable {
    let reminders: [Reminder]
}

struct Dates {
    static let current = Dates()
    
    func formatter() -> DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium
        return df
    }
}
