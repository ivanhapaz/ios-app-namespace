import XCTest
@testable import TudorCourt

/// Phase 5 gifts: sources (jewel from the servant, relic from Cromwell) and the
/// give-interactions (jewel → King, relic → priest).
final class GiftTests: XCTestCase {

    func testServantPaysAJewelForARumour() {
        let game = GameState()
        let sell = DilemmaCatalog.dilemma(for: .servantSpy).choiceA
        XCTAssertTrue(sell.grant == .jewel)
        game.choose(sell)
        XCTAssertTrue(game.has(.jewel))
    }

    func testPledgingToCromwellYieldsARelic() {
        let pledge = DilemmaCatalog.dilemma(for: .cromwell, holding: []).choiceA
        XCTAssertTrue(pledge.grant == .relic)
    }

    func testGiftingJewelToTheKingRaisesFavourAndSpendsIt() {
        let game = GameState()
        game.add(.jewel)
        let gift = DilemmaCatalog.dilemma(for: .king, holding: [.jewel])
        XCTAssertTrue(gift.choiceA.consume == .jewel)

        let favorBefore = game.meters.royalFavor
        let wealthBefore = game.meters.wealth
        game.choose(gift.choiceA)

        XCTAssertFalse(game.has(.jewel), "Gifting should consume the jewel")
        XCTAssertGreaterThan(game.meters.royalFavor, favorBefore)
        XCTAssertLessThan(game.meters.wealth, wealthBefore)
    }

    func testGiftingRelicToThePriestRaisesPiety() {
        let game = GameState()
        game.add(.relic)
        let gift = DilemmaCatalog.dilemma(for: .priest, holding: [.relic])
        XCTAssertTrue(gift.choiceA.consume == .relic)

        let pietyBefore = game.meters.piety
        game.choose(gift.choiceA)

        XCTAssertFalse(game.has(.relic), "Gifting should consume the relic")
        XCTAssertGreaterThan(game.meters.piety, pietyBefore)
    }
}
