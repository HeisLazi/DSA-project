import ballerina/test;

// Run with:  bal test   (from the server/ folder)
// STOP any running server first — tests start their own listener on 9090.
//
// These tests PASS once store.bal is fully fixed. Until then some fail —
// that's your compass. Fix store.bal until this is green.

@test:Config {}
function testParseDate() {
    int|error d = parseDate("2026-09-10");
    test:assertEquals(d, 20260910);
}

@test:Config {}
function testNightsCalc() {
    int|error n = calculateNights("2026-09-10", "2026-09-15");
    test:assertEquals(n, 5);
}

@test:Config {}
function testBadDateRejected() {
    int|error n = calculateNights("garbage", "2026-09-15");
    test:assertTrue(n is error);
}

@test:Config {}
function testOverlapDetected() {
    // existing 10-15 vs incoming 12-18: OVERLAP
    test:assertTrue(isOverlapping("2026-09-10", "2026-09-15", "2026-09-12", "2026-09-18"));
}

@test:Config {}
function testBackToBackAllowed() {
    // checkout on the 15th, checkin on the 15th: NOT an overlap
    test:assertFalse(isOverlapping("2026-09-10", "2026-09-15", "2026-09-15", "2026-09-18"));
}

@test:Config {}
function testInsideRangeOverlaps() {
    // incoming fully inside existing: OVERLAP
    test:assertTrue(isOverlapping("2026-09-10", "2026-09-15", "2026-09-11", "2026-09-14"));
}

@test:Config {}
function testIdenticalDatesOverlap() {
    test:assertTrue(isOverlapping("2026-09-10", "2026-09-15", "2026-09-10", "2026-09-15"));
}
