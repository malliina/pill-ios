//
//  PillTests.swift
//  PillTests
//
//  Created by Michael Skogberg on 25.9.2021.
//

import XCTest
@testable import Pill

class PillTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let cal = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2021
        dateComponents.month = 7
        dateComponents.day = 11
        dateComponents.hour = 8
        dateComponents.minute = 34
        let date = cal.date(from: dateComponents) ?? Date()
        let halt = Halt.nthWeek(NthSpec(start: date, nth: 2))
        let inThreeDays = cal.date(byAdding: .day, value: 6, to: date) ?? date
        XCTAssert(!halt.isHalted(date: inThreeDays))
        let inOneWeek = cal.date(byAdding: .day, value: 7, to: date) ?? date
        XCTAssert(halt.isHalted(date: inOneWeek))
        let inTenDays = cal.date(byAdding: .day, value: 10, to: date) ?? date
        XCTAssert(halt.isHalted(date: inTenDays))
        let inTwoWeeks = cal.date(byAdding: .day, value: 14, to: date) ?? date
        XCTAssert(!halt.isHalted(date: inTwoWeeks))
        let inThreeWeeks = cal.date(byAdding: .day, value: 21, to: date) ?? date
        XCTAssert(halt.isHalted(date: inThreeWeeks))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
