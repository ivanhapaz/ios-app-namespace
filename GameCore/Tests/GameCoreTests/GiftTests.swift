import XCTest
import GameCore

/// Gift loops: sources (jewel from the servant, relic from Cromwell) and the
/// give-interactions (jewel → King, relic → priest).
final class GiftTests: XCTestCase {

    func testServantPaysAJewelForARumour() {
        var engine = GameEngine()
        let sell = DilemmaCatalog.dilemma(for: .servantSpy).choiceA
        XCTAssertTrue(sell.grant == .jewel)
        engine.choose(sell)
        XCTAssertTrue(engine.has(.jewel))
    }

    func testPledgingToCromwellYieldsARelic() {
        let pledge = DilemmaCatalog.dilemma(for: .cromwell, holding: []).choiceA
        XCTAssertTrue(pledge.grant == .relic)
    }

    func testGiftingJewelToTheKingRaisesFavourAndSpendsIt() {
        var engine = GameEngine()
        engine.add(.jewel)
        let gift = DilemmaCatalog.dilemma(for: .king, holding: [.jewel])
        XCTAssertTrue(gift.choiceA.consume == .jewel)

        let favorBefore = engine.meters.royalFavor
        let wealthBefore = engine.meters.wealth
        engine.choose(gift.choiceA)

        XCTAssertFalse(engine.has(.jewel), "Gifting should consume the jewel")
        XCTAssertGreaterThan(engine.meters.royalFavor, favorBefore)
        XCTAssertLessThan(engine.meters.wealth, wealthBefore)
    }

    func testGiftingRelicToThePriestRaisesPiety() {
        var engine = GameEngine()
        engine.add(.relic)
        let gift = DilemmaCatalog.dilemma(for: .priest, holding: [.relic])
        XCTAssertTrue(gift.choiceA.consume == .relic)

        let pietyBefore = engine.meters.piety
        engine.choose(gift.choiceA)

        XCTAssertFalse(engine.has(.relic), "Gifting should consume the relic")
        XCTAssertGreaterThan(engine.meters.piety, pietyBefore)
    }
}
