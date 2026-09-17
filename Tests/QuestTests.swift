import XCTest
@testable import TudorCourt

/// Phase 5: inventory + the Boleyn-letter quest chain.
final class QuestTests: XCTestCase {

    func testInventoryAddRemoveHas() {
        let game = GameState()
        XCTAssertFalse(game.has(.letter))
        game.add(.letter)
        XCTAssertTrue(game.has(.letter))
        game.remove(.letter)
        XCTAssertFalse(game.has(.letter))
    }

    func testTakingTheLetterGrantsIt() {
        let game = GameState()
        let take = DilemmaCatalog.dilemma(for: .ladyInWaiting).choiceA
        XCTAssertTrue(take.grant == .letter)
        game.choose(take)
        XCTAssertTrue(game.has(.letter), "Taking the letter should place it in the inventory")
    }

    func testCromwellOffersDeliveryOnlyWhenHoldingLetter() {
        // Without the letter, Cromwell gives his default loyalty dilemma.
        let normal = DilemmaCatalog.dilemma(for: .cromwell, holdingLetter: false)
        XCTAssertFalse(normal.choiceA.text.localizedCaseInsensitiveContains("deliver"))

        // Holding the letter, he offers to buy it.
        let delivery = DilemmaCatalog.dilemma(for: .cromwell, holdingLetter: true)
        XCTAssertTrue(delivery.choiceA.consume == .letter)
    }

    func testDeliveringTheLetterConsumesItAndPays() {
        let game = GameState()
        game.add(.letter)
        let beforeWealth = game.meters.wealth
        let beforeFavor = game.meters.royalFavor

        let delivery = DilemmaCatalog.dilemma(for: .cromwell, holdingLetter: true)
        game.choose(delivery.choiceA)

        XCTAssertFalse(game.has(.letter), "Delivering should consume the letter")
        XCTAssertGreaterThan(game.meters.wealth, beforeWealth)
        XCTAssertGreaterThan(game.meters.royalFavor, beforeFavor)
    }
}
