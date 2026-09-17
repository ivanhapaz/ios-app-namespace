import XCTest
@testable import TudorCourt

/// Phase 1 sanity checks on the palace floor plan. These are pure-data tests
/// (no UIKit/SpriteKit), so they're fast and stable in CI.
final class RoomCatalogTests: XCTestCase {

    func testEveryRoomHasADefinition() {
        for id in RoomID.allCases {
            XCTAssertNotNil(RoomCatalog.all[id], "Missing definition for \(id)")
        }
    }

    func testGreatHallIsTheHub() {
        let hall = RoomCatalog.room(.greatHall)
        let destinations = Set(hall.doorways.map { $0.destination })
        XCTAssertEqual(destinations, [.privyChamber, .kitchens, .chapel, .gardens])
        XCTAssertTrue(hall.doorways.allSatisfy { !$0.locked }, "Hall doorways should be open")
    }

    /// Every open doorway must have a matching open doorway leading back, so the
    /// player can always return the way they came.
    func testOpenDoorwaysAreReciprocal() {
        for (id, def) in RoomCatalog.all {
            for door in def.doorways where !door.locked {
                guard let back = RoomCatalog.doorway(in: door.destination, leadingTo: id) else {
                    XCTFail("\(door.destination) has no doorway back to \(id)")
                    continue
                }
                XCTAssertFalse(back.locked, "Return doorway \(door.destination)→\(id) should be open")
                XCTAssertEqual(back.edge, door.edge.opposite,
                               "Return doorway \(door.destination)→\(id) should be on the opposite wall")
            }
        }
    }

    func testTowerPassagesAreLockedStoryRoutes() {
        let chapel = RoomCatalog.room(.chapel)
        let gardens = RoomCatalog.room(.gardens)
        XCTAssertTrue(chapel.doorways.contains { $0.destination == .tower && $0.locked })
        XCTAssertTrue(gardens.doorways.contains { $0.destination == .tower && $0.locked })

        // The Tower cannot be reached by any open doorway.
        for (_, def) in RoomCatalog.all {
            XCTAssertFalse(def.doorways.contains { $0.destination == .tower && !$0.locked },
                           "The Tower must only be reachable via locked, story-only passages")
        }
    }

    func testEdgeOppositesAreSymmetric() {
        XCTAssertEqual(Edge.north.opposite, .south)
        XCTAssertEqual(Edge.south.opposite, .north)
        XCTAssertEqual(Edge.east.opposite, .west)
        XCTAssertEqual(Edge.west.opposite, .east)
    }
}
