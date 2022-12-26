//
//  MTANearbyTests.swift
//  MTANearbyTests
//
//  Created by Jae Seung Lee on 12/25/22.
//

import XCTest

final class MTANearbyTests: XCTestCase {

    func testDecodeToRestResponseWrapper() throws {
        let exampleJSON = """
        {"tripUpdatesByTripId":{"104300_N..N":{"trip":{"tripId":"104300_N..N","routeId":"N","start":1672006980,"assigned":null,"trainId":"1N 1723 STL/DIT","direction":null},"stopTimeUpdateList":[{"stopId":"D43N","arrivalTime":1672006980,"departureTime":1672006980,"scheduledTrack":"0A","actualTrack":"0A"},{"stopId":"N10N","arrivalTime":1672007220,"departureTime":1672007220,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N09N","arrivalTime":1672007280,"departureTime":1672007280,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N08N","arrivalTime":1672007370,"departureTime":1672007370,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N07N","arrivalTime":1672007490,"departureTime":1672007490,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N06N","arrivalTime":1672007580,"departureTime":1672007580,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N05N","arrivalTime":1672007640,"departureTime":1672007640,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N04N","arrivalTime":1672007730,"departureTime":1672007730,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N03N","arrivalTime":1672007880,"departureTime":1672007880,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"N02N","arrivalTime":1672007940,"departureTime":1672007940,"scheduledTrack":"E2","actualTrack":"E2"},{"stopId":"R41N","arrivalTime":1672008180,"departureTime":1672008180,"scheduledTrack":"F4","actualTrack":"F4"},{"stopId":"R36N","arrivalTime":1672008510,"departureTime":1672008510,"scheduledTrack":"F4","actualTrack":"F4"},{"stopId":"R31N","arrivalTime":1672008810,"departureTime":1672008810,"scheduledTrack":"F4","actualTrack":"F4"},{"stopId":"Q01N","arrivalTime":1672009440,"departureTime":1672009440,"scheduledTrack":"H2","actualTrack":"H2"},{"stopId":"R22N","arrivalTime":1672009560,"departureTime":1672009560,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R21N","arrivalTime":1672009680,"departureTime":1672009680,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R20N","arrivalTime":1672009770,"departureTime":1672009770,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R19N","arrivalTime":1672009860,"departureTime":1672009860,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R18N","arrivalTime":1672009950,"departureTime":1672009950,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R17N","arrivalTime":1672010040,"departureTime":1672010040,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R16N","arrivalTime":1672010160,"departureTime":1672010160,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R15N","arrivalTime":1672010250,"departureTime":1672010250,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R14N","arrivalTime":1672010370,"departureTime":1672010370,"scheduledTrack":"A2","actualTrack":"A2"},{"stopId":"R13N","arrivalTime":1672010520,"departureTime":1672010520,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R11N","arrivalTime":1672010610,"departureTime":1672010610,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R60N","arrivalTime":1672010760,"departureTime":1672010760,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R09N","arrivalTime":1672010895,"departureTime":1672010895,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R08N","arrivalTime":1672011030,"departureTime":1672011030,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R06N","arrivalTime":1672011090,"departureTime":1672011090,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R05N","arrivalTime":1672011210,"departureTime":1672011210,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R04N","arrivalTime":1672011300,"departureTime":1672011300,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R03N","arrivalTime":1672011390,"departureTime":1672011390,"scheduledTrack":"G2","actualTrack":"G2"},{"stopId":"R01N","arrivalTime":1672011480,"departureTime":1672011480,"scheduledTrack":"G2","actualTrack":"G2"}]}}, "vehiclesByStopId":{"104300_N..N":{"status":"IN_TRANSIT_TO","stopId":"D43N","stopSequence":null,"timestamp":1672006980,"trip":{"tripId":"104300_N..N","routeId":"N","start":1672006980,"assigned":null,"trainId":"1N 1723 STL/DIT","direction":null}},"108000_N..S":{"status":"IN_TRANSIT_TO","stopId":"R01S","stopSequence":null,"timestamp":1672009200,"trip":{"tripId":"108000_N..S","routeId":"N","start":1672009200,"assigned":null,"trainId":"1N 1800 DIT/STL","direction":"SOUTH"}},"106700_J..S":{"status":"IN_TRANSIT_TO","stopId":"G05S","stopSequence":null,"timestamp":1672008420,"trip":{"tripId":"106700_J..S","routeId":"J","start":1672008420,"assigned":null,"trainId":"1J 1747 P-A/BRD","direction":"SOUTH"}},"103100_E..S":{"status":"STOPPED_AT","stopId":"F07S","stopSequence":5,"timestamp":1672006787,"trip":{"tripId":"103100_E..S","routeId":"E","start":1672006260,"assigned":true,"trainId":"1E 1711 P-A/WTC","direction":"SOUTH"}},"099531_E..S":{"status":"STOPPED_AT","stopId":"A34S","stopSequence":20,"timestamp":1672006778,"trip":{"tripId":"099531_E..S","routeId":"E","start":1672004119,"assigned":true,"trainId":"1E 1635 P-A/WTC","direction":"SOUTH"}}}}
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        var feed: RestResponseWrapper?
        do {
            feed = try decoder.decode(RestResponseWrapper.self, from: exampleJSON.data(using: .utf8)!)
        } catch {
            print("\(error)")
        }
        
        XCTAssertNotNil(feed)
    }

}
