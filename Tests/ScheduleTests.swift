import XCTest
@testable import TudorCourt

/// Phase 4 clock logic: slot advancement, day roll-over, and the King's routine.
final class ScheduleTests: XCTestCase {

    func testSlotAdvanceAndDayRollover() {
        XCTAssertEqual(TimeSlot.morning.advanced().slot, .midday)
        XCTAssertFalse(TimeSlot.morning.advanced().newDay)

        XCTAssertEqual(TimeSlot.midday.advanced().slot, .evening)
        XCTAssertFalse(TimeSlot.midday.advanced().newDay)

        XCTAssertEqual(TimeSlot.evening.advanced().slot, .morning)
        XCTAssertTrue(TimeSlot.evening.advanced().newDay, "Evening should roll to a new day")
    }

    func testKingSchedule() {
        XCTAssertEqual(TimeSlot.morning.kingRoom, .chapel)
        XCTAssertEqual(TimeSlot.midday.kingRoom, .greatHall)
        XCTAssertEqual(TimeSlot.evening.kingRoom, .privyChamber)
    }

    func testWaitingThreeSlotsAdvancesOneDay() {
        let game = GameState()
        XCTAssertEqual(game.day, 1)
        XCTAssertEqual(game.slot, .morning)

        game.wait() // morning -> midday
        XCTAssertEqual(game.slot, .midday)
        XCTAssertEqual(game.day, 1)

        game.wait() // midday -> evening
        game.wait() // evening -> morning, day 2
        XCTAssertEqual(game.slot, .morning)
        XCTAssertEqual(game.day, 2)
    }

    func testChoiceAdvancesTheClock() {
        let game = GameState()
        game.apply(MeterDelta()) // neutral choice
        XCTAssertEqual(game.slot, .midday)
        XCTAssertNil(game.gameOver)
    }
}
