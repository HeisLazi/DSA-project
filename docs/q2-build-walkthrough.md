# Q2 gRPC — Build Walkthrough (type-along, verified)

Every command and every code block in this file was executed on YOUR machine
(Ballerina 2201.10.0, WSL) and passed: full end-to-end run plus 7 green tests.
Work through the phases in order. Each chunk = read the explanation, type the
code, run the verify step, commit. Do not paste-read-continue — you defend this
live, so type every line.

Estimated total: 5-7 focused hours. Everything below the final commit is
optional polish.

---

## Phase 0 — Preflight (5 min)

```bash
cd ~/Projects/work/DSA-project
git checkout main && git pull
git checkout -b feat/grpc-proto
bal version        # must print 2201.10.0
```

Delete the hello-world mains — they print noise and, in the server package,
run BEFORE the gRPC listener starts:

```bash
rm question2-grpc/server/main.bal
rm question2-grpc/client/main.bal
```

**Why:** a `bal` package runs `main()` first when it exists. In the server
that means "Hello, World!" prints on every startup and it delays/confuses the
listener lifecycle. We don't want a main in the server at all; the client gets
its own main later, written by us.

---

## Phase 1 — accommodation.proto (the 15 marks)

Marking says: correct .proto defining all services, messages, and streaming
types. Get every operation from the brief into this one file.

Create `question2-grpc/accommodation.proto`. Type it in this order.

### 1a. Header

```proto
syntax = "proto3";

package accommodation;
```

**Explain:** `proto3` is the current protobuf dialect (no `required` keyword,
zero-value defaults). `package accommodation` namespaces everything — the
generated Ballerina file uses these names. There is no filename-based
namespace, so this line is what keeps our messages from colliding with anyone
else's.

### 1b. Enum

```proto
enum PropertyStatus {
    AVAILABLE = 0;
    BOOKED = 1;
    INACTIVE = 2;
}
```

**Explain:** protobuf enums are int32 on the wire with names attached. The
first value MUST be 0 — proto3 semantics require every enum to have a zero
value meaning "unset/default". Forgetting this is a classic codegen error.

### 1c. The data messages

```proto
message Property {
    string property_id = 1;
    string name = 2;
    string location = 3;
    string property_type = 4;
    double price_per_night = 5;
    PropertyStatus status = 6;
}

message PropertyList {
    repeated Property properties = 1;
}
```

**Explain:** the numbers are FIELD NUMBERS, not values — the field's identity
on the wire. Unique per message, never renumber once anything depends on them.
`repeated` = an array (becomes `Property[]` in Ballerina).

### 1d. Request/response messages (one per RPC)

Type these after the two above. One message pair per operation keeps the
contract readable and gives us room to grow fields without breaking anything:

```proto
message AddPropertyRequest {
    string name = 1;
    string location = 2;
    string property_type = 3;
    double price_per_night = 4;
    PropertyStatus status = 5;
}

message AddPropertyResponse {
    string property_id = 1;
    string message = 2;
}

message UserRequest {
    string user_id = 1;
    string name = 2;
    string role = 3;        // "HOST" or "GUEST"
}

message CreateUsersResponse {
    int32 count = 1;
    string message = 2;
}

message UpdatePropertyRequest {
    string property_id = 1;
    string name = 2;
    double price_per_night = 3;
    PropertyStatus status = 4;
}

message UpdatePropertyResponse {
    string message = 1;
}

message RemovePropertyRequest {
    string property_id = 1;
}

message ListRequest {
    string location = 1;    // empty = no filter
    double max_price = 2;   // 0 = no filter
}

message SearchRequest {
    string property_id = 1;
}

message SearchResponse {
    Property property = 1;
    string status = 2;      // "AVAILABLE" or "NOT_AVAILABLE"
}

message BookRequest {
    string property_id = 1;
    string guest_id = 2;
    string check_in = 3;    // YYYY-MM-DD
    string check_out = 4;   // YYYY-MM-DD
}

message BookResponse {
    string cart_id = 1;
    string message = 2;
}

message ConfirmRequest {
    string cart_id = 1;
}

message BookingConfirmation {
    string booking_id = 1;
    string property_id = 2;
    int32 nights = 3;
    double total_cost = 4;
    string message = 5;
}
```

**Design notes you must be able to say out loud:**
- Dates as `string` in `YYYY-MM-DD`, not protobuf timestamps: we only ever
  COMPARE dates (before/after/equal). String comparison of zero-padded ISO
  dates is already chronological. Simple, and simple to defend.
- `SearchResponse.status` instead of an error for a miss: the brief says
  search returns a "Not Available" STATUS — so a miss is a valid response, not
  a gRPC error.
- `BookResponse.cart_id`: the "booking cart" from the brief needs a handle.
  The cart id is how confirm finds the temporary request.

### 1e. The service block

```proto
service AccommodationService {
    rpc addProperty (AddPropertyRequest) returns (AddPropertyResponse);
    rpc createUsers (stream UserRequest) returns (CreateUsersResponse);
    rpc updateProperty (UpdatePropertyRequest) returns (UpdatePropertyResponse);
    rpc removeProperty (RemovePropertyRequest) returns (PropertyList);
    rpc listAvailableProperties (ListRequest) returns (stream Property);
    rpc searchProperty (SearchRequest) returns (SearchResponse);
    rpc bookProperty (BookRequest) returns (BookResponse);
    rpc confirmBooking (ConfirmRequest) returns (BookingConfirmation);
}
```

**The four RPC kinds — this is the thing they will ask you:**
- `stream` appears NOWHERE = unary (one request, one response). 6 of ours.
- `stream` on the REQUEST side = client streaming: many requests arrive, one
  response leaves. Only `createUsers`.
- `stream` on the RETURN side = server streaming: one request arrives, many
  responses leave. Only `listAvailableProperties`.
- both sides = bidirectional. We don't use it; say "no operation in the brief
  needs many-to-many, so adding it would be inventing requirements".

### 1f. Generate and verify

```bash
cd question2-grpc
bal grpc --input accommodation.proto --output server --mode service
bal grpc --input accommodation.proto --output client --mode client
bal grpc --input accommodation.proto --output client
ls server client
```

Expected files:
- `server/accommodation_pb.bal` (types + descriptor) and
  `server/accommodationservice_service.bal` (empty service skeleton)
- `client/accommodation_pb.bal`, `client/accommodationservice_client.bal`
  (demo client — DELETE it, see below), plus stub file

```bash
rm client/accommodationservice_client.bal
```

**Why:** the generated client file contains its OWN `ep` variable and its own
`main()` — it will collide with ours (redeclared symbol errors). Keep only the
`_pb.bal` types; we write the real client ourselves in Phase 6.

Open the generated `accommodationservice_service.bal` and READ the signatures.
This is your map for Phases 3-5:

```ballerina
remote function addProperty(AddPropertyRequest value) returns AddPropertyResponse|error {}
remote function createUsers(stream<UserRequest, grpc:Error?> clientStream) returns CreateUsersResponse|error {}
remote function listAvailableProperties(ListRequest value) returns stream<Property, error?>|error {}
```

Unary = plain in/plain out. Client streaming = the stream is the PARAMETER.
Server streaming = the stream is in the RETURN type. The proto is mirrored 1:1.

**Naming warning:** the generated Ballerina records keep snake_case field
names (`property_id`, `price_per_night`) — they are NOT camelCased. Use the
snake_case names exactly as generated.

Commit:

```bash
cd ~/Projects/work/DSA-project
git add question2-grpc/accommodation.proto question2-grpc/server question2-grpc/client
git commit -m "feat(grpc): define proto contract with 8 RPCs"
```

---

## Phase 2 — store.bal: types, tables, dates

New file `question2-grpc/server/store.bal`. Three concerns live here: data
model records, the in-memory tables, and date helpers.

### 2a. Records

```ballerina
public type InternalProperty record {|
    readonly string propertyId;
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
```

**Explain:** `{| |}` is a CLOSED record — the compiler rejects unknown fields,
which turns typos into compile errors instead of runtime bugs. `readonly` on
`propertyId` is what allows it to be a table key (keys must be readonly).

**Why a separate `InternalProperty` when the proto already made `Property`?**
The wire type belongs to protobuf (snake_case, float, generated — never touch
it). Our store record is ours: camelCase, an extra `hostId`, free to evolve.
Convert at the boundary with one small function (Phase 3). Say it as:
"internal model and wire model are deliberately separated".

### 2b. Tables

```ballerina
table<InternalProperty> key(propertyId) propertiesTable = table [];
map<Booking> confirmedBookings = {};
map<CartItem> bookingCart = {};
```

**Explain:** the brief says "use maps or tables". A keyed TABLE gives keyed
lookup like a map PLUS query expressions and type-checked rows — so we use a
table for the collection that needs filtering (properties) and maps for the
id->record lookups (bookings, carts). State is in-memory; there is one
process, so that satisfies "maintain the state of properties and bookings".

### 2c. Date helpers

```ballerina
// Compares dates as YYYYMMDD integers. Safe because the assignment only
// needs ordering checks (before/after/equal), and zero-padded ISO dates
// compare correctly as strings — we just need them as numbers for
// subtraction-free overlap logic. 2026-09-10 -> 20260910.
public function parseDate(string date) returns int|error {
    int[] parts = [];
    string current = "";
    foreach var ch in date {
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
    return parts[0] * 10000 + parts[1] * 100 + parts[2];
}

public function calculateNights(string checkIn, string checkOut) returns int|error {
    int inDays = check parseDate(checkIn);
    int outDays = check parseDate(checkOut);
    return outDays - inDays;
}
```

**Explain each construct:**
- `int|error` — Ballerina has no exceptions; failure is a VALUE in the return
  union. Callers must deal with it or the compiler complains.
- `check` — "if the expression is an error, return it from here immediately".
- `foreach var ch in date` — strings are iterable char lists. (Do NOT write
  `char ch` — the type is `string:Char`, `var` sidesteps it.)
- Ballerina strings have NO `.split()` method — hand-rolling the dash-split is
  not stubbornness, it is the language.

Verify (this also proves your store compiles):

```bash
cd question2-grpc/server && bal build
```

### 2d. First tests

`question2-grpc/server/tests/store_test.bal`:

```ballerina
import ballerina/test;

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
```

**Explain:** test functions live in the same package, so they call package
functions directly — NO module prefix. `@test:Config {}` registers the
function with the test runner. Run `bal test`.

Commit:

```bash
git add question2-grpc/server
git commit -m "feat(server): add in-memory data store with date helpers"
```

---

## Phase 3 — The four simple RPCs

Open the generated `accommodationservice_service.bal` and fill the EMPTY
bodies. Leave the streaming two for Phase 4 (delete nothing). Your file needs
these imports and module-level variables at the top (replacing what's there):

```ballerina
import ballerina/grpc;

listener grpc:Listener ep = new (9090);

int nextPropertyNum = 1;
int nextCartNum = 1;
int nextBookingNum = 1;
```

### 3a. addProperty

```ballerina
    remote function addProperty(AddPropertyRequest value) returns AddPropertyResponse|error {
        string propId = "PROP-" + nextPropertyNum.toString();
        nextPropertyNum += 1;

        InternalProperty prop = {
            propertyId: propId,
            name: value.name,
            location: value.location,
            propertyType: value.property_type,
            pricePerNight: value.price_per_night,
            status: value.status.toString(),
            hostId: "HOST-UNKNOWN"
        };
        lock {
            propertiesTable.add(prop);
        }
        return {
            property_id: propId,
            message: "Property " + propId + " registered successfully"
        };
    }
```

**Explain:**
- `remote function` marks a network-callable method. Plain `function` will NOT
  be reachable over gRPC.
- The brief says the system "returns a unique property_id" — we mint
  PROP-1, PROP-2, ... from a counter. Deterministic, readable, demo-friendly.
- `value.status.toString()` — the generated enum is a string-valued Ballerina
  enum, so it converts cleanly for storage.
- `lock` wraps every mutation of shared state. It is a direct answer to the
  brief's "must handle concurrent requests": two simultaneous addProperty
  calls cannot interleave inside the lock. Mention it by name in the demo.
- The return literal is the wire message built inline — fine for two fields.

### 3b. searchProperty

```ballerina
    remote function searchProperty(SearchRequest value) returns SearchResponse|error {
        InternalProperty? found = propertiesTable[value.property_id];
        if found is () {
            return {status: "NOT_AVAILABLE"};
        }
        return {property: toWire(found), status: "AVAILABLE"};
    }
```

**Explain:**
- `propertiesTable[key]` returns `InternalProperty?` — nil is "not found".
  This is the table-as-dictionary pattern.
- `is ()` is the nil check; after it, the compiler narrows `found` to the
  record. Flow-typed narrowing is everywhere in Ballerina.
- Omitting `property` in the miss response is legal because generated proto
  records have defaults for every field — partial initialisation is fine.

### 3c. updateProperty

```ballerina
    remote function updateProperty(UpdatePropertyRequest value) returns UpdatePropertyResponse|error {
        InternalProperty? existing = propertiesTable[value.property_id];
        if existing is () {
            return error grpc:NotFoundError("No property with id: " + value.property_id);
        }
        InternalProperty updated = {
            propertyId: existing.propertyId,
            name: value.name,
            location: existing.location,
            propertyType: existing.propertyType,
            pricePerNight: value.price_per_night,
            status: value.status.toString(),
            hostId: existing.hostId
        };
        lock {
            _ = propertiesTable.remove(value.property_id);
            propertiesTable.add(updated);
        }
        return {message: "Property " + value.property_id + " updated"};
    }
```

**Explain:**
- `error grpc:NotFoundError(...)` — gRPC-standard status codes as Ballerina
  error VALUES. NotFound for a bad id, InvalidArgument for bad input,
  AlreadyExists for conflicts. Choosing the right one is cheap competence.
- Update = remove + re-add inside one `lock`. On a keyed table you cannot
  assign `tbl[key] = record` like on a map — remove+add is the clean verified
  pattern.
- `_ =` before remove: table.remove returns the removed row and Ballerina
  requires the result to be consumed. `_` = "deliberately discarded".

### 3d. removeProperty

```ballerina
    remote function removeProperty(RemovePropertyRequest value) returns PropertyList|error {
        InternalProperty? existing = propertiesTable[value.property_id];
        if existing is () {
            return error grpc:NotFoundError("No property with id: " + value.property_id);
        }
        string hostLocation = existing.location;
        lock {
            _ = propertiesTable.remove(value.property_id);
        }
        // Brief: the removal response is the FULL remaining list for that region
        Property[] matching = [];
        foreach InternalProperty prop in propertiesTable {
            if prop.location == hostLocation {
                matching.push(toWire(prop));
            }
        }
        return {properties: matching};
    }
```

**Read the brief again on this one** — it is a trap: the response is not an
ack, it is the new full list of that HOST'S REGION. We snapshot `location`
BEFORE removing (the row is gone afterwards).

Add the two helpers at the BOTTOM of the same file (outside the service):

```ballerina
function toWire(InternalProperty prop) returns Property {
    PropertyStatus status = <PropertyStatus>prop.status;
    return {
        property_id: prop.propertyId,
        name: prop.name,
        location: prop.location,
        property_type: prop.propertyType,
        price_per_night: prop.pricePerNight,
        status: status
    };
}
```

**Explain:** one boundary function, internal -> wire. `<PropertyStatus>` casts
the stored string back to the generated enum for the wire message.

Verify + commit:

```bash
bal build
git add -A && git commit -m "feat(server): add unary CRUD RPCs"
```

---

## Phase 4 — The streaming pair (the marks that separate groups)

### 4a. listAvailableProperties — SERVER streaming

```ballerina
    remote function listAvailableProperties(ListRequest value) returns stream<Property, error?>|error {
        Property[] matching = [];
        foreach InternalProperty prop in propertiesTable {
            if value.location != "" && prop.location != value.location {
                continue;
            }
            if value.max_price > 0.0 && prop.pricePerNight > value.max_price {
                continue;
            }
            matching.push(toWire(prop));
        }
        return matching.toStream();
    }
```

**Explain:**
- Return type `stream<Property, error?>` = "a sequence of Property, errors
  possible during iteration". The client receives them ONE BY ONE over the
  network — that is the server-streaming contract, not an array download.
- Filters are optional: empty string means "ignore location", 0 means "ignore
  price". Both filters AND neither filter work — demo all three cases.
- `matching.toStream()` converts a Ballerina array into a stream. Under gRPC
  each element goes out as its own protobuf message.

### 4b. createUsers — CLIENT streaming

```ballerina
    remote function createUsers(stream<UserRequest, grpc:Error?> clientStream) returns CreateUsersResponse|error {
        int count = 0;
        check clientStream.forEach(function(UserRequest user) {
            count += 1;
        });
        return {
            count: count,
            message: count.toString() + " users registered"
        };
    }
```

**Explain:**
- The REQUEST is the stream: the client pushes many UserRequest messages,
  then signals DONE. Only then does our return value go back — ONE
  confirmation for the whole batch, exactly as the brief demands.
- `forEach` consumes the stream to completion. The `check` propagates a
  mid-stream transport error.

Commit:

```bash
git add -A && git commit -m "feat(server): add streaming RPCs for listing and bulk user creation"
```

---

## Phase 5 — Booking: cart, overlap, confirm (the hard marks)

### 5a. bookProperty — validate and park in the cart

```ballerina
    remote function bookProperty(BookRequest value) returns BookResponse|error {
        // validate first, fail fast
        if value.check_out <= value.check_in {
            return error grpc:InvalidArgumentError("checkOut must be after checkIn");
        }
        if value.guest_id.trim() == "" {
            return error grpc:InvalidArgumentError("guestId is required");
        }
        InternalProperty? prop = propertiesTable[value.property_id];
        if prop is () {
            return error grpc:NotFoundError("No property with id: " + value.property_id);
        }
        string cartId = "CART-" + nextCartNum.toString();
        nextCartNum += 1;
        lock {
            bookingCart[cartId] = {
                cartId: cartId,
                propertyId: value.property_id,
                guestId: value.guest_id,
                checkIn: value.check_in,
                checkOut: value.check_out
            };
        }
        return {
            cart_id: cartId,
            message: "Added to cart. Confirm to finalise booking."
        };
    }
```

**Explain:** the brief's exact flow — validate dates, add to a TEMPORARY cart,
return. Nothing is "booked" yet; confirmation is where conflicts get resolved.
Validation lives at the boundary, before any logic touches the data.

### 5b. isOverlapping — the 1-line heart of the system

Add below the service block, next to `toWire`:

```ballerina
// Half-open interval semantics: [checkIn, checkOut). A checkout and a
// checkin on the same date do NOT conflict — one guest leaves morning,
// the next arrives afternoon. String comparison works because
// YYYY-MM-DD zero-padded dates sort chronologically.
public function isOverlapping(string existingIn, string existingOut,
                              string newIn, string newOut) returns boolean {
    return newIn < existingOut && newOut > existingIn;
}
```

**This is your best defence answer.** Two ranges overlap exactly when each
starts before the other ends. Treating checkout day as "not available from
that morning" (half-open) is what makes back-to-back bookings legal —
10-15 + 15-18 is fine, 10-15 + 14-18 is not.

### 5c. confirmBooking — check, cost, commit, clear

```ballerina
    remote function confirmBooking(ConfirmRequest value) returns BookingConfirmation|error {
        CartItem? item = bookingCart[value.cart_id];
        if item is () {
            return error grpc:NotFoundError("No booking cart with id: " + value.cart_id);
        }
        InternalProperty? prop = propertiesTable[item.propertyId];
        if prop is () {
            return error grpc:NotFoundError("Property " + item.propertyId + " no longer exists");
        }

        // 1. availability: compare against every confirmed booking of this property
        foreach string bk in confirmedBookings.keys() {
            Booking? maybeB = confirmedBookings[bk];
            if maybeB is Booking && maybeB.propertyId == item.propertyId
                    && isOverlapping(maybeB.checkIn, maybeB.checkOut, item.checkIn, item.checkOut) {
                return error grpc:AlreadyExistsError(
                    "Property " + item.propertyId + " is already booked "
                    + maybeB.checkIn + " to " + maybeB.checkOut);
            }
        }

        // 2. cost = price per night x nights
        int nights = check calculateNights(item.checkIn, item.checkOut);
        if nights <= 0 {
            return error grpc:InvalidArgumentError("checkOut must be after checkIn");
        }
        float totalCost = prop.pricePerNight * <float>nights;

        string bookingId = "BOOK-" + nextBookingNum.toString();
        nextBookingNum += 1;

        lock {
            confirmedBookings[bookingId] = {
                bookingId: bookingId,
                propertyId: item.propertyId,
                guestId: item.guestId,
                checkIn: item.checkIn,
                checkOut: item.checkOut,
                nights: nights,
                totalCost: totalCost
            };
            // 3. clear the guest's temporary request
            _ = bookingCart.remove(value.cart_id);
        }

        return {
            booking_id: bookingId,
            property_id: item.propertyId,
            nights: nights,
            total_cost: totalCost,
            message: "Booking confirmed for " + item.guestId
        };
    }
```

**Explain — the brief lists exactly three duties, in this order:**
1. verify availability (overlap check vs confirmed bookings only — the cart
   itself is per-guest temporary, it never blocks anyone),
2. calculate total cost (rate x nights),
3. return confirmation AND clear the cart. Confirming twice therefore fails
   with NotFound on the second call — the cart is gone. That is correct
   behaviour; say it if they poke at it.

`<float>nights` — explicit numeric cast; Ballerina never mixes int/float
silently.

### 5d. The edge-case tests (P5's matrix, now your code)

Add to `tests/store_test.bal`:

```ballerina
@test:Config {}
function testOverlapDetected() {
    // existing 10-15 vs incoming 12-18: overlap
    test:assertTrue(isOverlapping("2026-09-10", "2026-09-15", "2026-09-12", "2026-09-18"));
}

@test:Config {}
function testBackToBackAllowed() {
    // checkout on the 15th, checkin on the 15th: NOT an overlap
    test:assertFalse(isOverlapping("2026-09-10", "2026-09-15", "2026-09-15", "2026-09-18"));
}

@test:Config {}
function testInsideRangeOverlaps() {
    // incoming fully inside existing
    test:assertTrue(isOverlapping("2026-09-10", "2026-09-15", "2026-09-11", "2026-09-14"));
}

@test:Config {}
function testIdenticalDatesOverlap() {
    test:assertTrue(isOverlapping("2026-09-10", "2026-09-15", "2026-09-10", "2026-09-15"));
}

@test:Config {}
function testSameDayIsZeroNights() {
    int|error n = calculateNights("2026-09-10", "2026-09-10");
    test:assertEquals(n, 0);
}
```

```bash
bal test     # 7 passing, 0 failing
```

**Important:** stop any running server before `bal test` — tests boot the
service's own listener on 9090 and you get "Address already in use".

Commit:

```bash
git add -A && git commit -m "feat(booking): add cart and overlap-checked confirmation"
```

---

## Phase 6 — The client (10 marks, and your live demo)

### 6a. Script first, menu later

Write `question2-grpc/client/main.bal` EXACTLY as below and run it against
the server. This is a scripted end-to-end run proving every RPC; the menu in
6b wraps the same calls.

```ballerina
import ballerina/io;

AccommodationServiceClient ep = check new ("http://localhost:9090");

public function main() returns error? {
    // unary: add two properties
    AddPropertyResponse r1 = check ep->addProperty(
        {name: "Ocean Cabin", location: "Swakopmund", property_type: "CABIN",
         price_per_night: 850.0, status: AVAILABLE});
    AddPropertyResponse r2 = check ep->addProperty(
        {name: "Dune Flat", location: "Swakopmund", property_type: "APARTMENT",
         price_per_night: 600.0, status: AVAILABLE});
    io:println("added: ", r1.property_id, ", ", r2.property_id);

    // client streaming: create 3 users, one confirmation
    CreateUsersStreamingClient uc = check ep->createUsers();
    check uc->sendUserRequest({user_id: "U1", name: "Anna", role: "HOST"});
    check uc->sendUserRequest({user_id: "U2", name: "Ben", role: "GUEST"});
    check uc->sendUserRequest({user_id: "U3", name: "Cara", role: "GUEST"});
    check uc->complete();
    CreateUsersResponse? cres = check uc->receiveCreateUsersResponse();
    io:println("users: ", cres?.message);

    // server streaming: list Swakopmund
    stream<Property, error?> props =
        check ep->listAvailableProperties({location: "Swakopmund", max_price: 0.0});
    check props.forEach(function(Property p) {
        io:println("listing: ", p.property_id, " ", p.name, " N$", p.price_per_night);
    });

    // book + confirm
    BookResponse br = check ep->bookProperty(
        {property_id: r1.property_id, guest_id: "U2",
         check_in: "2026-09-20", check_out: "2026-09-23"});
    BookingConfirmation conf = check ep->confirmBooking({cart_id: br.cart_id});
    io:println("confirmed: ", conf.booking_id, " nights=", conf.nights,
               " total=N$", conf.total_cost);

    // double-booking is rejected with a readable error
    BookResponse br2 = check ep->bookProperty(
        {property_id: r1.property_id, guest_id: "U3",
         check_in: "2026-09-22", check_out: "2026-09-25"});
    BookingConfirmation|error bad = ep->confirmBooking({cart_id: br2.cart_id});
    if bad is error {
        io:println("correctly rejected: ", bad.message());
    }
}
```

**Constructs to be able to explain:**
- `ep->method(...)` — arrow call on a client OBJECT; that is a remote
  invocation, the whole point of the question.
- Client streaming is three steps, and each step has its own generated method:
  `ep->createUsers()` gets the streaming client (note: NO argument),
  `->sendUserRequest(...)` per message, `->complete()` to end the stream,
  `->receiveCreateUsersResponse()` for the single reply.
- The server stream is consumed with `.forEach` — the loop body runs once per
  message AS IT ARRIVES.
- `cres?.message` — safe access on a nullable; prints nothing if nil.

### 6b. Run it end to end

Terminal 1:

```bash
cd question2-grpc/server && bal run
```

Terminal 2:

```bash
cd question2-grpc/client && bal run
```

Expected output (your numbers may differ if you ran things):

```
added: PROP-1, PROP-2
users: 3 users registered
listing: PROP-1 Ocean Cabin N$850.0
listing: PROP-2 Dune Flat N$600.0
confirmed: BOOK-1 nights=3 total=N$2550.0
correctly rejected: Property PROP-1 is already booked 2026-09-20 to 2026-09-23
```

If you see that block, your 50 marks are functionally complete.

### 6c. Menu wrapper

Replace `main` with a menu loop. The two handlers below show both patterns
(unary and streaming); the remaining six are the same shapes — copy one of
the two and swap the request fields.

```ballerina
import ballerina/io;

AccommodationServiceClient ep = check new ("http://localhost:9090");

public function main() returns error? {
    boolean running = true;
    while running {
        io:println("
========= Accommodation =========
 1. Add property        2. Search property
 3. Update property     4. Remove property
 5. List available      6. Create users (batch)
 7. Book property       8. Confirm booking
 0. Exit");
        string choice = io:readln("choice: ").trim();
        if choice == "1" { doAdd(); }
        else if choice == "5" { doList(); }
        else if choice == "0" { running = false; }
        else { io:println("not implemented yet"); }
    }
}

function doAdd() returns error? {
    string name = io:readln("name: ").trim();
    string location = io:readln("location: ").trim();
    string ptype = io:readln("type: ").trim();
    float price = check float:fromString(io:readln("price/night: ").trim());
    AddPropertyResponse res = check ep->addProperty(
        {name: name, location: location, property_type: ptype,
         price_per_night: price, status: AVAILABLE});
    io:println(res.message);
}

function doList() returns error? {
    string location = io:readln("location filter (enter = all): ").trim();
    string maxPrice = io:readln("max price (0 = any): ").trim();
    stream<Property, error?> props = check ep->listAvailableProperties(
        {location: location, max_price: check float:fromString(maxPrice)});
    check props.forEach(function(Property p) {
        io:println(p.property_id, "  ", p.name, "  ", p.location, "  N$", p.price_per_night);
    });
}
```

**Explain:** `io:readln` blocks for a line, `.trim()` eats the newline.
Errors from handlers bubble to `main`'s `error?` — for the demo, print them
nicely instead: wrap each handler call as
`if doAdd() is error { io:println("operation failed"); }` once the rest works.
Errors as MESSAGES, never stack traces — that is marking criteria.

Commit:

```bash
git add -A && git commit -m "feat(client): add interactive gRPC client for all 8 operations"
git push -u origin feat/grpc-proto
```

Open the PR. The PR trail is the evidence every member contributed.

---

## Phase 7 — Polish (only after everything above works)

- `bal format` in both packages before every commit from now on.
- README section (in your slice):

```markdown
## Running Q2 (gRPC)
Terminal 1:  cd question2-grpc/server && bal run
Terminal 2:  cd question2-grpc/client && bal run

Regenerate stubs after editing the proto:
  bal grpc --input accommodation.proto --output server --mode service
  bal grpc --input accommodation.proto --output client --mode client
  bal grpc --input accommodation.proto --output client
```

- Rehearse out loud: the four RPC kinds (stream keyword position), why dates
  are strings, half-open overlap, what `lock` protects, why `removeProperty`
  returns the regional list.

---

## Pitfalls found the hard way (all hit during verification)

1. **Generated records keep snake_case** (`price_per_night`). The concept
   tutorial's claim that `bal grpc` camelCases them is wrong — use the exact
   generated names.
2. **Delete `main.bal` from the server package.** It runs before the listener
   and prints noise on every start.
3. **Delete the generated `accommodationservice_client.bal`** — it declares
   its own `ep` and `main` and collides with yours (redeclared symbol).
4. **Keyed tables:** `tbl[k] = v` does NOT work (map syntax). Verified
   pattern: `tbl.add(row)`, `_ = tbl.remove(k)`, read via `tbl[k]` which
   returns `T?`. The `_ =` on remove is REQUIRED — Ballerina rejects a
   discarded return.
5. **No `string.split()` in Ballerina.** Hand-roll the dash parse (Phase 2c)
   or import `ballerina/lang.regexp`. We chose the char walk — simpler to
   defend.
6. **`foreach var ch`, not `char ch`** — the type is `string:Char` and `char`
   does not exist.
7. **`bal test` starts the gRPC listener.** Stop the running server first or
   you get "Address already in use" from the TEST run.
8. **Client streaming has no argument:** `ep->createUsers()` — the generated
   `CreateUsersStreamingClient` does send/complete/receive.
9. **Enum round-trip:** store as string (`status.toString()`), cast back with
   `<PropertyStatus>status` for the wire.
10. **Field defaults save you:** generated proto records initialise every
    field, so `{status: "NOT_AVAILABLE"}` (no `property`) is legal.

---

## Defence cheat-sheet

- Why server streaming for list? Potentially hundreds of properties; the
  guest sees results as each arrives instead of one huge payload after a long
  wait. One request, many responses.
- Why client streaming for createUsers? Bulk registration; the server sends
  ONE confirmation when the whole batch lands, exactly as the brief requires.
- Why unary for the rest? One request, one definitive answer — add, update,
  book, confirm are single transactions.
- How does overlap work? Each range is half-open [in, out). Ranges conflict
  iff each starts before the other ends: `newIn < existingOut && newOut >
  existingIn`. Same-day turnover passes; the tests prove all four edge cases.
- Concurrency? Ballerina services handle each request on its own strand; all
  shared-state mutations are inside `lock`, so interleaved requests cannot
  corrupt the tables.
- Where is state? In-memory keyed table for properties, maps for confirmed
  bookings and carts — the brief allows maps/tables for the in-memory store.
