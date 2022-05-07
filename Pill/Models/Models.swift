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
    
    // https://developer.apple.com/documentation/foundation/nsdatecomponents/1410442-weekday
    static func gregorian(cal: Calendar, date: Date) throws -> WeekDay {
        switch cal.component(.weekday, from: date) {
        case 1: return sun
        case 2: return mon
        case 3: return tue
        case 4: return wed
        case 5: return thu
        case 6: return fri
        case 7: return sat
        default: throw PillError.general("Invalid weekday value.")
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
    case daysOfMonth
    
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
    case once(Date), daily([WeekDay], Time), monthly(Time), daysOfMonth([Int], Time)
    
    var interval: Interval {
        switch self {
        case .once(_): return .none
        case .daily(_, _): return .daily
        case .monthly(_): return .monthly
        case .daysOfMonth(_, _): return .daysOfMonth
        }
    }
    var time: Time {
        switch self {
        case .once(let date): return date.time
        case .daily(_, let t): return t
        case .monthly(let t): return t
        case .daysOfMonth(_, let t): return t
        }
    }
    var weekDays: [WeekDay]? {
        switch self {
        case .once(_): return nil
        case .daily(let days, _): return days
        case .monthly(_): return nil
        case .daysOfMonth(_, _): return nil
        }
    }
    var monthDays: [Int]? {
        switch self {
        case .once(_): return nil
        case .daily(_, _): return nil
        case .monthly(_): return nil
        case .daysOfMonth(let days, _): return days
        }
    }
}

struct NthSpec: Codable {
    let start: Date
    let nth: Int
}

enum Halt: Codable {
    case nthWeek(NthSpec), nthMonth(NthSpec)
    
    var interval: HaltInterval {
        switch self {
        case .nthWeek(_): return .nthWeek
        case .nthMonth(_): return .nthMonth
        }
    }
    
    var nth: Int? {
        switch self {
        case .nthWeek(let spec): return spec.nth
        case .nthMonth(let spec): return spec.nth
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
            return remainder == 0
        case .nthMonth(let spec):
            let calendar = Calendar.current
            let from = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: spec.start) ?? spec.start
            let to = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let daysComponents = calendar.dateComponents([.month], from: from, to: to)
            let months = daysComponents.value(for: .month) ?? 0
            let remainder = (months + 1) % spec.nth
            return remainder == 0
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
    
    var components: DateComponents {
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
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
    // All days including selection states
    var whenWeekDays: [WeekDaySelection]
    var selectedWeekDays: [WeekDay] { whenWeekDays.filter({ day in day.isSelected }).map({ day in day.day }) }
    // All days of month including selection states
    var whenDaysOfMonth: [DayOfMonthSelection]
    var selectedDaysOfMonth: [Int] { whenDaysOfMonth.filter({ day in day.isSelected }).map({ day in day.day}) }
    var timeAsDate: Date
    var haltInterval: HaltInterval
    var haltNth: Int
    var start: Date
    
    func upcoming(from: Date, limit: Int) -> [Date] {
        guard limit > 0 else { return [] }
        guard enabled else { return [] }
        let cal = Calendar.current
        let time = timeAsDate.time
        let startCandidate = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from) ?? from
        let range = 0..<limit
        switch whenInterval {
        case .none:
            let now = Date()
            return startCandidate > now ? [startCandidate] : []
        case .daily:
            guard !selectedWeekDays.isEmpty else { return [] }
            let tomorrow = cal.date(byAdding: .day, value: 1, to: startCandidate) ?? from
            // If equal, take next day, prob recursion
            let next = from < startCandidate ? startCandidate : tomorrow
            let potentialRange = range.compactMap { i in
                cal.date(byAdding: .day, value: i, to: next)
            }
            let potentialDays = potentialRange.filter({ date in
                selectedWeekDays.contains { day in
                    (try? WeekDay.gregorian(cal: cal, date: date) == day) ?? false
                }
            })
            let halt = asHalt()
            let batch = potentialDays.filter { date in
                !(halt?.isHalted(date: date) ?? false)
            }
            if let nextFrom = cal.date(byAdding: .day, value: limit, to: from), batch.count < limit {
//                log.info("Recurse after batch \(batch.count) remaining \(limit-batch.count) from \(nextFrom)")
                return batch + upcoming(from: nextFrom, limit: limit - batch.count)
            } else {
                return batch
            }
        case .monthly:
            let now = Date()
            if now > startCandidate {
                guard let nextCandidate = cal.date(byAdding: .month, value: 1, to: startCandidate) else { return [] }
                return upcoming(from: nextCandidate, limit: limit)
            } else {
                let potentialMonths = range.compactMap { i in
                    cal.date(byAdding: .month, value: i, to: startCandidate)
                }
                let halt = asHalt()
                let batch = potentialMonths.filter { date in
                    !(halt?.isHalted(date: date) ?? false)
                }
                if let nextFrom = cal.date(byAdding: .month, value: limit, to: from), batch.count < limit {
//                    log.info("Recurse after batch \(batch.count) remaining \(limit-batch.count) from \(mostDistant)")
                    return batch + upcoming(from: nextFrom, limit: limit - batch.count)
                } else {
                    return batch
                }
            }
        case .daysOfMonth:
            guard !selectedDaysOfMonth.isEmpty else { return [] }
            let tomorrow = cal.date(byAdding: .day, value: 1, to: startCandidate) ?? from
            // If equal, take next day, prob recursion
            let next = from < startCandidate ? startCandidate : tomorrow
            let potentialDays = range.compactMap { i in
                cal.date(byAdding: .day, value: i, to: next)
            }.filter { date in
                let daysComponents = cal.dateComponents([.day], from: date)
                let day = daysComponents.value(for: .day) ?? 0
                return whenDaysOfMonth.filter { $0.isSelected }.contains { doms in
                    return doms.day == day
                }
            }
            let halt = asHalt()
            let batch = potentialDays.filter { date in
                !(halt?.isHalted(date: date) ?? false)
            }
            if let nextFrom = cal.date(byAdding: .day, value: limit, to: from), batch.count < limit {
//                log.info("Recurse after batch \(batch.count) remaining \(limit-batch.count) from \(nextFrom)")
                return batch + upcoming(from: nextFrom, limit: limit - batch.count)
            } else {
                return batch
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
            return .daily(selectedWeekDays, timeAsDate.time)
        case .monthly:
            return .monthly(timeAsDate.time)
        case .daysOfMonth:
            let daysOfMonth = whenDaysOfMonth.filter({ dayOfMonth in
                dayOfMonth.isSelected
            }).map({ dayOfMonth in
                dayOfMonth.day
            })
            return .daysOfMonth(daysOfMonth, timeAsDate.time)
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
        let enabledDays = when.weekDays ?? WeekDay.allCases
        let weekDays = WeekDay.allCases.map { weekDay in
            WeekDaySelection(day: weekDay, isSelected: enabledDays.contains(weekDay))
        }
        let allDays = Array(1...31)
        let enabledMonthDays = when.monthDays ?? allDays
        let monthDays = allDays.map { day in
            DayOfMonthSelection(day: day, isSelected: enabledMonthDays.contains(day))
        }
        return MutableReminder(id: id, enabled: enabled, name: name, whenInterval: when.interval, whenWeekDays: weekDays, whenDaysOfMonth: monthDays, timeAsDate: when.time.today, haltInterval: halt?.interval ?? HaltInterval.none, haltNth: halt?.nth ?? 2, start: start)
    }
    
    func upcoming(from: Date, limit: Int) -> [Date] {
        return mutable.upcoming(from: from, limit: limit)
    }
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

struct SchedulingTime: Codable {
    let when: TimeInterval
    var asDate: Date {
        Date(timeIntervalSince1970: when)
    }
}
