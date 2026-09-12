// data model section

public type InternalProperty record {|
    // table keys are readonly ; eg string id; also we using closed brackets
    // so unkown feilds arent compiled
    readonly string id;
    string name;
    string location;
    string propertyType;
    float pricePerNight;
    string status;
    string hostId;
|};

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



// storage section

// used the id we made readonly so the table is searchable also
// cause sir asked for that in doc
table<InternalProperty> key(id) propertiesTable = table [];

// for map the key lives outside but a table the key is in the object
// so its kinda like an sql table i think
map<Booking> confirmedBookings = {};

map<CartItem> bookingCart = {};



// functions they are lwk data helpers so just reusable code
// so we only have to it write once and just call it later on for use

public function parseDate(string date) returns int|error {
    int[] parts = [];
    string current = "";

    // there are no chr in ballerina and you cant even use
    // string.split() in this language bruh so i used a loop
    foreach string str in date {
        if str == "-" {
            parts.push(check int:fromString(current));
            current = "";
        } else {
            current = current + str;
        }
    }
    parts.push(check int:fromString(current));

    if parts.length() != 3 {
        return error("Invalid date format, expected YYYY-MM-DD: " + date);
    }

    // this is to create the date format parts[0] is the year in the array
    // so to get smth like 20260122 we gotta shift the year by mulpilying it by 10000
    // then shift the month by 100 and just add the day and then boom its done.
    return parts[0] * 10000 + parts[1] * 100 + parts[2];
}

public function calculateNights(string checkIn, string checkOut) returns int|error {
    //added error handling to this also with check keyword so it wont execute unless
    // parseDate function above returns an int
    int inDays = check parseDate(checkIn);
    int outDays = check parseDate(checkOut);
    return outDays - inDays;
}

// overlap check just so you cant book while someone is still in there
public function isOverlapping(string existingIn, string existingOut, string newIn, string newOut) returns boolean {
    return newIn < existingOut && newOut > existingIn;
}
