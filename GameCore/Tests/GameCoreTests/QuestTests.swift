import XCTest
import GameCore

/// Inventory + the Boleyn-letter quest chain (incl. the delayed arrest).
final class QuestTests: XCTestCase {

    func testInventoryAddRemoveHas() {
        var engine = GameEngine()
        XCTAssertFalse(engine.has(.letter))
        engine.add(.letter)
        XCTAssertTrue(engine.has(.letter))
        engine.remove(.letter)
        XCTAssertFalse(engine.has(.letter))
    }

    func testTakingTheLetterGrantsIt() {
        var engine = GameEngine()
        let take = DilemmaCatalog.dilemma(for: .ladyInWaiting).choiceA
        XCTAssertTrue(take.grant == .letter)
        engine.choose(take)
        XCTAssertTrue(engine.has(.letter), "Taking the letter should place it in the inventory")
    }

    func testCromwellOffersDeliveryOnlyWhenHoldingLetter() {
        let normal = DilemmaCatalog.dilemma(for: .cromwell, holding: [])
        XCTAssertFalse(normal.choiceA.text.lowercased().contains("deliver"))

        let delivery = DilemmaCatalog.dilemma(for: .cromwell, holding: [.letter])
        XCTAssertTrue(delivery.choiceA.consume == .letter)
    }

    func testDeliveringTheLetterConsumesItAndPays() {
        var engine = GameEngine()
        engine.add(.letter)
        let beforeWealth = engine.meters.wealth
        let beforeFavor = engine.meters.royalFavor

        let delivery = DilemmaCatalog.dilemma(for: .cromwell, holding: [.letter])
        engine.choose(delivery.choiceA)

        XCTAssertFalse(engine.has(.letter), "Delivering should consume the letter")
        XCTAssertGreaterThan(engine.meters.wealth, beforeWealth)
        XCTAssertGreaterThan(engine.meters.royalFavor, beforeFavor)
    }

    func testDeliveringTheLetterArrestsTheLadyTwoDaysLater() {
        var engine = GameEngine()
        engine.add(.letter)

        let delivery = DilemmaCatalog.dilemma(for: .cromwell, holding: [.letter])
        engine.choose(delivery.choiceA)

        XCTAssertNil(engine.lastFiredEvent, "The arrest should not fire immediately")
        XCTAssertEqual(engine.pendingEvents.count, 1, "The consequence should be queued")
        XCTAssertEqual(engine.meters.piety, 50)

        var safety = 0
        while engine.lastFiredEvent == nil && safety < 20 {
            engine.wait()
            safety += 1
        }

        XCTAssertNotNil(engine.lastFiredEvent, "The arrest should fire once its day arrives")
        XCTAssertGreaterThanOrEqual(engine.day, 3, "It should be ~two days after delivery")
        XCTAssertEqual(engine.meters.piety, 40, "Selling out the lady costs 10 Piety")
        XCTAssertTrue(engine.pendingEvents.isEmpty)
    }
}
