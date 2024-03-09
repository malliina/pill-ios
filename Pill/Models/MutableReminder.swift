import Foundation

struct MutableReminder {
  static let logger = LoggerFactory.shared.system(MutableReminder.self)
  var log: Logger { MutableReminder.logger }

  static func create() -> MutableReminder {
    let reminder = Reminder(
      id: UUID().uuidString, enabled: true, name: "",
      when: When.once(Date.now.addingTimeInterval(300)), halt: nil, start: Date())
    return reminder.mutable
  }
  
  let id: String
  var enabled: Bool
  var name: String
  var whenInterval: Interval
  // All days including selection states
  var whenWeekDays: [WeekDaySelection]
  var selectedWeekDays: [WeekDay] {
    whenWeekDays.filter { day in day.isSelected }.map { day in day.day }
  }
  // All days of month including selection states
  var whenDaysOfMonth: [DayOfMonthSelection]
  var selectedDaysOfMonth: [Int] {
    whenDaysOfMonth.filter { day in day.isSelected }.map { day in day.day }
  }
  var timeAsDate: Date
  var haltInterval: HaltInterval
  var haltNth: Int
  var start: Date

  func upcoming(from: Date, now: Date, limit: Int) -> [Date] {
    guard limit > 0 else { return [] }
    guard enabled else { return [] }
    let cal = Calendar.current
    let time = timeAsDate.time
    let startCandidate =
      cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: from) ?? from
    let range = 0..<limit
    switch whenInterval {
    case .none:
      return startCandidate > now ? [startCandidate] : []
    case .daily:
      guard !selectedWeekDays.isEmpty else { return [] }
      let tomorrow = cal.date(byAdding: .day, value: 1, to: startCandidate) ?? from
      let next = from <= startCandidate ? startCandidate : tomorrow
      let potentialRange = range.compactMap { i in
        cal.date(byAdding: .day, value: i, to: next)
      }
      let potentialDays = potentialRange.filter { date in
        selectedWeekDays.contains { day in
          (try? WeekDay.gregorian(cal: cal, date: date) == day) ?? false
        }
      }
      let halt = asHalt()
      let batch = potentialDays.filter { date in
        !(halt?.isHalted(date: date) ?? false) && date > now
      }
      return if let nextFrom = cal.date(byAdding: .day, value: limit, to: from), batch.count < limit {
        batch + upcoming(from: nextFrom, now: now, limit: limit - batch.count)
      } else {
        batch
      }
    case .monthly:
      if from > startCandidate {
        guard let nextCandidate = cal.date(byAdding: .month, value: 1, to: startCandidate) else {
          return []
        }
        return upcoming(from: nextCandidate, now: now, limit: limit)
      } else {
        let potentialMonths = range.compactMap { i in
          cal.date(byAdding: .month, value: i, to: startCandidate)
        }
        let halt = asHalt()
        let batch = potentialMonths.filter { date in
          !(halt?.isHalted(date: date) ?? false) && date > now
        }
        return if let nextFrom = cal.date(byAdding: .month, value: limit, to: from), batch.count < limit {
          batch + upcoming(from: nextFrom, now: now, limit: limit - batch.count)
        } else {
          batch
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
        !(halt?.isHalted(date: date) ?? false) && date > now
      }
      return if let nextFrom = cal.date(byAdding: .day, value: limit, to: from), batch.count < limit {
        batch + upcoming(from: nextFrom, now: now, limit: limit - batch.count)
      } else {
        batch
      }
    case .lastDayOfMonth:
      let batch = range.compactMap { int in cal.date(byAdding: .day, value: int, to: startCandidate)
      }.filter { date in
        isLastDayOfMonth(date) && date > now
      }
      return if let nextFrom = cal.date(byAdding: .day, value: range.count, to: from), batch.count < limit
      {
        batch + upcoming(from: nextFrom, now: now, limit: limit - batch.count)
      } else {
        batch
      }
    }
  }

  func isLastDayOfMonth(_ date: Date) -> Bool {
    guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) else {
      return false
    }
    return if let startMonth = date.components.month, let tomorrowMonth = nextDay.components.month,
      startMonth != tomorrowMonth
    {
      true
    } else {
      false
    }
  }

  func asHalt() -> Halt? {
    return switch haltInterval {
    case .none:
      nil
    case .nthWeek:
      Halt.nthWeek(NthSpec(start: start, nth: haltNth))
    case .nthMonth:
      Halt.nthMonth(NthSpec(start: start, nth: haltNth))
    }
  }

  func asWhen() -> When {
    let time = timeAsDate.time
    switch whenInterval {
    case .none:
      return .once(start.at(time: time))
    case .daily:
      return .daily(selectedWeekDays, time)
    case .monthly:
      return .monthly(time)
    case .daysOfMonth:
      let daysOfMonth = whenDaysOfMonth.filter({ dayOfMonth in
        dayOfMonth.isSelected
      }).map({ dayOfMonth in
        dayOfMonth.day
      })
      return .daysOfMonth(daysOfMonth, time)
    case .lastDayOfMonth:
      return .lastDayOfMonth(time)
    }
  }

  var immutable: Reminder {
    Reminder(id: id, enabled: enabled, name: name, when: asWhen(), halt: asHalt(), start: start)
  }
}
