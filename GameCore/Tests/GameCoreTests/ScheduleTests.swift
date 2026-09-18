import XCTest
import GameCore

/// Clock logic: slot advancement, day roll-over, and the King's routine.
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
        var engine = GameEngine()
        XCTAssertEqual(engine.day, 1)
        XCTAssertEqual(engine.slot, .morning)

        engine.wait() // morning -> midday
        XCTAssertEqual(engine.slot, .midday)
        XCTAssertEqual(engine.day, 1)

        engine.wait() // midday -> evening
        engine.wait() // evening -> morning, day 2
        XCTAssertEqual(engine.slot, .morning)
        XCTAssertEqual(engine.day, 2)
    }

    func testChoiceAdvancesTheClock() {
        var engine = GameEngine()
        engine.apply(MeterDelta()) // neutral
        XCTAssertEqual(engine.slot, .midday)
        XCTAssertNil(engine.gameOver)
    }
}
