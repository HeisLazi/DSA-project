import ballerina/io;

// ============================================================
// store.bal — the server's in-memory database + date helpers
// There are 6 BUGS/blanks in this file. Each is marked.
// Fix them one at a time. After each fix run:  bal build
// in the server/ folder. Green = move to the next.
// ============================================================

// ---------- DATA MODEL ----------

// BUG A: this record is OPEN ({| |} is closed). Change the braces so unknown
// fields are REJECTED at compile time. Also: `id` must be a TABLE KEY later,
// and table keys must be readonly — add that keyword to id's type.
public type InternalProperty record {
    string id;
    string name;
    string location;
    string propertyType;
    float pricePerNight;
    string status;
    string hostId;
};

public type Booking record {|
    string bookingId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
    int nights;
    float totalCost;
|};

public type CartItem record {|
    string cartId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
|};

// ---------- STORAGE ----------

// BUG B: this table declaration is missing the KEY.
// The brief says assets/listings need a unique identifier — declare `id`
// as the key. (Compare with a plain map: what does a keyed table give you
// that a map doesn't? Answer for the defence.)
table<InternalProperty> propertiesTable = table [];

// confirmed bookings: bookingId -> Booking
map<Booking> confirmedBookings = {};

// the "booking cart" from the brief: cartId -> temporary request
map<CartItem> bookingCart = {};

// ---------- DATE HELPERS ----------

// Ballerina has NO string.split(). This function walks the string char by
// char and rebuilds the number. "2026-09-10" should become 20260910.
public function parseDate(string date) returns int|error {
    int[] parts = [];
    string current = "";

    // BUG C: strings in Ballerina are iterable — but the loop below has
    // the wrong type annotation and won't compile. `char` doesn't exist
    // as a type. Fix the loop so it iterates single characters of `date`.
    foreach char ch in date {
        if ch == "-" {
            parts.push(check int:fromString(current));
            current = "";
        } else {
            current = current + ch;
        }
    }
    parts.push(check int:fromString(current));

    if parts.length() != 3 {
        return error("Invalid date format, expected YYYY-MM-DD: " + date);
    }

    // BUG D: assemble the number. Parts are [year, month, day].
    // Combine them so 2026, 9, 10 becomes 20260910.
    // (year * 10000) + (month * ?) + day — fill in the ? and the day term.
    return parts[0] * 10000;
}

// nights between two YYYY-MM-DD dates. Uses parseDate above.
public function calculateNights(string checkIn, string checkOut) returns int|error {
    // BUG E: both calls below are missing the error-handling keyword that
    // means "if this returns an error, return it from HERE immediately".
    // Add it to both lines.
    int inDays = parseDate(checkIn);
    int outDays = parseDate(checkOut);
    return outDays - inDays;
}

// ---------- THE OVERLAP CHECK (heart of the booking system) ----------
//
// Two date ranges overlap when EACH starts before the OTHER ends:
//
//   existing:  [inA ---------- outA)
//   new:              [inB ---------- outB)
//                    ^^^^ overlap ^^^^
//
// Dates as "YYYY-MM-DD" strings compare correctly with < > because
// zero-padded ISO dates sort chronologically as text.
//
// BUG F: the comparison below has its operators wrong — it currently
// claims EVERYTHING overlaps. Fix the two comparisons so:
//   - back-to-back (existing 10-15, new 15-18) is NOT an overlap
//   - genuinely overlapping ranges ARE detected
public function isOverlapping(string existingIn, string existingOut,
                              string newIn, string newOut) returns boolean {
    return newIn > existingOut && newOut < existingIn;
}
