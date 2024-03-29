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
    return switch self {
    case .mon: "Mon"
    case .tue: "Tue"
    case .wed: "Wed"
    case .thu: "Thu"
    case .fri: "Fri"
    case .sat: "Sat"
    case .sun: "Sun"
    }
  }

  // https://developer.apple.com/documentation/foundation/nsdatecomponents/1410442-weekday
  static func gregorian(cal: Calendar, date: Date) throws -> WeekDay {
    return switch cal.component(.weekday, from: date) {
    case 1: sun
    case 2: mon
    case 3: tue
    case 4: wed
    case 5: thu
    case 6: fri
    case 7: sat
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
  case none, daily, monthly, daysOfMonth, lastDayOfMonth

  var id: String { self.rawValue }
}

enum HaltInterval: String, CaseIterable, Codable, Identifiable {
  case none
  case nthWeek
  case nthMonth
  var id: String { self.rawValue }
}

enum When: Codable {
  case once(Date)
  case daily([WeekDay], Time)
  case monthly(Time)
  case daysOfMonth([Int], Time)
  case lastDayOfMonth(Time)

  var interval: Interval {
    return switch self {
    case .once(_): .none
    case .daily(_, _): .daily
    case .monthly(_): .monthly
    case .daysOfMonth(_, _):  .daysOfMonth
    case .lastDayOfMonth(_): .lastDayOfMonth
    }
  }
  var time: Time {
    return switch self {
    case .once(let date): date.time
    case .daily(_, let t): t
    case .monthly(let t): t
    case .daysOfMonth(_, let t): t
    case .lastDayOfMonth(let t): t
    }
  }
  var weekDays: [WeekDay]? {
    return switch self {
    case .once(_): nil
    case .daily(let days, _): days
    case .monthly(_): nil
    case .daysOfMonth(_, _): nil
    case .lastDayOfMonth(_): nil
    }
  }
  var monthDays: [Int]? {
    return switch self {
    case .once(_): nil
    case .daily(_, _): nil
    case .monthly(_): nil
    case .daysOfMonth(let days, _): days
    case .lastDayOfMonth(_):  nil
    }
  }

  var describe: String {
    switch self {
    case .once(let date):
      let formattedDate = Dates.current.formatter().string(from: date)
      return "\(formattedDate)"
    case .daily(let weekDays, let time):
      if weekDays == WeekDay.allCases {
        return "Daily at \(time.describe)"
      } else {
        let days = weekDays.map { $0.short }.joined(separator: ", ")
        return "\(days) at \(time.describe)"
      }
    case .monthly(let time):
      return "Monthly at \(time.describe)"
    case .daysOfMonth(let days, _):
      let str = days.map { i in
        "\(i)"
      }.joined(separator: ", ")
      let word = days.count > 1 ? "Days" : "Day"
      return "\(word) \(str) of month"
    case .lastDayOfMonth(let time):
      return "Last day of month at \(time.describe)"
    }
  }
}

struct NthSpec: Codable {
  let start: Date
  let nth: Int
}

enum Halt: Codable {
  case nthWeek(NthSpec)
  case nthMonth(NthSpec)

  var interval: HaltInterval {
    return switch self {
    case .nthWeek(_): .nthWeek
    case .nthMonth(_): .nthMonth
    }
  }

  var spec: NthSpec {
    return switch self {
    case .nthWeek(let spec): spec
    case .nthMonth(let spec): spec
    }
  }

  var nth: Int { spec.nth }

  var intervalWord: String {
    return switch self {
    case .nthWeek(_): "week"
    case .nthMonth(_): "month"
    }
  }

  var describe: String {
    "every \(nth) \(intervalWord) starting \(spec.start.describe)"
  }

  func isHalted(date: Date) -> Bool {
    switch self {
    case .nthWeek(let spec):
      let calendar = Calendar.current
      let from =
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: spec.start) ?? spec.start
      let to = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
      let daysComponents = calendar.dateComponents([.day], from: from, to: to)
      let days = daysComponents.value(for: .day) ?? 0
      let remainder = ((days / 7) + 1) % spec.nth
      return remainder == 0
    case .nthMonth(let spec):
      let calendar = Calendar.current
      let from =
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: spec.start) ?? spec.start
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
    Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
  }
}

struct Reminder: Codable, Identifiable {
  static let log = LoggerFactory.shared.system(Reminder.self)
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
    return MutableReminder(
      id: id, enabled: enabled, name: name, whenInterval: when.interval, whenWeekDays: weekDays,
      whenDaysOfMonth: monthDays, timeAsDate: when.time.today,
      haltInterval: halt?.interval ?? HaltInterval.none, haltNth: halt?.nth ?? 2, start: start)
  }

  private func initialFrom(from: Date) -> Date? {
    let cal = Calendar.current
    let time = when.time
    return switch when.interval {
    case .none:
      cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: start)
    case .daily:
      cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from)
    case .monthly:
      cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: start)
    case .daysOfMonth:
      cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from)
    case .lastDayOfMonth:
      cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: start)
    }
  }

  func upcoming(now: Date, limit: Int) -> [Date] {
    guard let initial = initialFrom(from: now) else { return [] }
    return mutable.upcoming(from: initial, now: now, limit: limit)
  }
  
  var describe: String {
    when.describe
  }
}

struct Reminders: Codable {
  let reminders: [Reminder]
}

struct Upcoming: Identifiable {
  let id, title: String
  let next: Date

  func nextFormatted() -> String {
    ReminderEdit.dateFormatter.string(from: next)
  }
}

struct Dates {
  static let current = Dates()

  func formatter() -> DateFormatter {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .medium
    return df
  }
  
  func dateOnly() -> DateFormatter {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
  }
}

struct SchedulingTime: Codable {
  let when: TimeInterval
  var asDate: Date {
    Date(timeIntervalSince1970: when)
  }
}

struct DatedReminder {
  let date: Date
  let reminder: Reminder
}
