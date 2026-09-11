# Ballerina gRPC — Working Tutorial (Q2)

Everything here was verified on this machine with Ballerina 2201.10.0.

## 0. Setup (already done)

- Ballerina 2201.10.0 at `~/.local/ballerina/usr/lib/ballerina/bin/bal`
- On PATH via `~/.bashrc`. New terminal = `bal` just works.
- Check: `bal version`

---

## 1. Protobuf syntax — the whole language you need

A `.proto` file has three things: a header, `message` blocks (data), and a
`service` block (the RPCs).

```proto
syntax = "proto3";        // always proto3
package accommodation;    // becomes the Ballerina module/namespace
```

### Messages = records

```proto
message Property {
    string property_id = 1;
    string name = 2;
    double price_per_night = 3;
    bool is_active = 4;
}
```

The `= 1`, `= 2` are **field numbers**, not values. They are the wire identity
of the field. Rules:
- Must be unique within the message.
- Never renumber a field once someone depends on it.
- 1-15 encode in one byte, so give those to your most-used fields.

Types you'll use: `string`, `int32`, `int64`, `double`, `bool`.

### Repeated = arrays

```proto
message PropertyList {
    repeated Property properties = 1;   // becomes Property[] in Ballerina
}
```

### Enums

```proto
enum PropertyStatus {
    AVAILABLE = 0;      // first value MUST be 0
    BOOKED = 1;
    INACTIVE = 2;
}
```

### Nesting

Messages can hold other messages. That's how you build `Booking` containing a
`Property`.

---

## 2. The four RPC types — this is worth marks

The `stream` keyword position decides everything.

```proto
service AccommodationService {
    rpc addProperty (AddRequest) returns (AddResponse);                    // unary
    rpc listAvailable (FilterRequest) returns (stream Property);           // server streaming
    rpc createUsers (stream User) returns (CreateUsersResponse);           // client streaming
    rpc chat (stream Msg) returns (stream Msg);                            // bidirectional
}
```

| Pattern | `stream` where | Meaning |
|---|---|---|
| Unary | nowhere | one request, one response |
| Server streaming | on the **return** | one request, many responses |
| Client streaming | on the **param** | many requests, one response |
| Bidirectional | both | many/many |

Assignment needs the first three. Bidirectional is optional (bonus territory).

---

## 3. Codegen — the command

```bash
bal grpc --input accommodation.proto --output <dir> --mode service   # server skeleton
bal grpc --input accommodation.proto --output <dir> --mode client    # client skeleton
bal grpc --input accommodation.proto --output <dir>                  # stub only
```

First run downloads protoc (~one time, slow). After that it's fast.

**Workflow rule:** regenerate the stub into your project, but write your real
logic in a SEPARATE file. Never edit `*_pb.bal` — it gets overwritten.

---

## 4. What the generated server looks like

For the four RPC types above, `--mode service` produced exactly this:

```ballerina
import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: SMOKE_DESC}
service "SmokeService" on ep {

    remote function unaryCall(Req value) returns Res|error {
    }

    remote function clientStream(stream<Req, grpc:Error?> clientStream) returns Res|error {
    }

    remote function serverStream(Req value) returns stream<Res, error?>|error {
    }

    remote function biDi(stream<Req, grpc:Error?> clientStream) returns stream<Res, error?>|error {
    }
}
```

Read the signatures — they mirror the proto exactly:
- unary: plain in, plain out
- client streaming: `stream<T, grpc:Error?>` **parameter**
- server streaming: `stream<T, error?>` **return type**

`remote function` (not `function`) is required — it's how Ballerina marks a
network-callable method.

---

## 5. Ballerina language notes for this project

### Records — your data model

```ballerina
type Booking record {|
    string bookingId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
    decimal totalCost;
|};
```

`{| |}` = closed record (no extra fields allowed). Prefer it — the compiler
catches typos.

### Tables — your in-memory database

The assignment says "use maps or tables". Table with a key is the better answer:

```ballerina
table<Property> key(propertyId) propertiesTable = table [];

// insert
propertiesTable.add(newProperty);

// lookup by key
Property? p = propertiesTable[propId];

// query
Property[] cheap = from Property p in propertiesTable
                   where p.pricePerNight < 500.0
                   select p;
```

That query syntax is Ballerina's built-in query expression — use it for your
filters and it demos well.

### Error handling — the union type

Ballerina has no exceptions. Errors are values in a union:

```ballerina
Property|error result = findProperty(id);

if result is error {
    return error grpc:NotFoundError("Property not found");
}
// after this line the compiler KNOWS result is a Property
```

`check` is shorthand for "if error, return it up":

```ballerina
Property p = check findProperty(id);
```

### Concurrency — `isolated`

The brief says "must handle concurrent requests". Ballerina services are
concurrent by default. To make shared state safe:

```ballerina
isolated table<Property> key(propertyId) propertiesTable = table [];

isolated function addProp(Property p) {
    lock {
        propertiesTable.add(p);
    }
}
```

Mention `lock` in your presentation — it's a direct answer to the
"handle concurrent requests" requirement.

---

## 6. Running things

```bash
cd question2-grpc/server && bal run     # terminal 1
cd question2-grpc/client && bal run     # terminal 2
```

`bal build` compiles to a JAR in `target/bin/`.

---

## 7. Pitfalls

- Field numbers: never reuse or renumber.
- Enum's first entry must be `= 0`.
- Regenerating stubs overwrites `*_pb.bal` — keep logic elsewhere.
- Server must be running before the client, or you get a connection refused.
- Both server and client packages need `import ballerina/grpc;`.
- Don't edit generated files and then wonder why your changes vanished.

---

# PART 2 — Development Practices

The marks are for working code, but these practices are what stop a 5-person
group breaking each other's work in the last 48 hours. Also: you have to
DEFEND this live, so write code you can explain.

---

## 8. Git — the parts that actually matter

### Branch per feature, never commit to main

```bash
git checkout main
git pull                          # always start from latest
git checkout -b feat/grpc-proto   # your own branch
# ...work...
git add question2-grpc/accommodation.proto
git commit -m "feat(grpc): define proto contract with 8 RPCs"
git push -u origin feat/grpc-proto
```

Then open a Pull Request. Why bother in a student project? Because the PR is
the record of who did what — and the brief REQUIRES all members to be
contributors. A PR is proof.

Branch naming: `feat/`, `fix/`, `docs/`, `refactor/` + short description.
`feat/booking-overlap`, not `lazi-branch-2`.

### Commit messages — Conventional Commits

```
<type>(<scope>): <what changed, imperative>

feat(grpc): add server-streaming for listAvailableProperties
fix(booking): correct off-by-one in nights calculation
docs(readme): add setup instructions
refactor(server): extract overlap check into helper
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Rules:
- Imperative mood: "add feature", not "added" or "adds".
- Under ~72 chars for the subject line.
- Explain WHY in the body if it isn't obvious.

Bad: `update`, `fixed stuff`, `asdf`, `final version FINAL v2`.

### Commit size — small and often

One logical change per commit. If your message needs the word "and", it's
probably two commits.

Good: "add Property message to proto" then "add booking RPCs to proto".
Bad: one 800-line commit at 23:00 on 13 Sept.

That last one is also exactly what the plagiarism clause is looking for.
A steady commit history is evidence you wrote it.

### Never commit these

Your `.gitignore` must cover:
```
target/
*.jar
.DS_Store
Dependencies.toml
```

Never commit: credentials, API keys, `.env` files, build output, IDE folders.
Once a secret is in git history it is effectively public — removing it means
rewriting history for everyone.

### Before you push, always

```bash
git status          # what am I actually committing?
git diff --staged   # read it. every line.
bal build           # does it still compile?
```

Pushing broken code to a shared branch blocks four other people.

---

## 9. Code structure — files and naming

### One concern per file

```
question2-grpc/server/
  accommodation_pb.bal   # GENERATED — never touch
  service.bal            # the RPC endpoints
  store.bal              # tables + data access
  booking.bal            # overlap + cost logic
  types.bal              # your own records
```

Why: when the stub regenerates, only `_pb.bal` changes. Your logic is safe.
Also, five files of 80 lines beat one file of 400 when you're demoing under
pressure and need to find something fast.

### Naming

- Functions: verbs. `calculateTotalCost`, `isOverlapping`, `findProperty`
- Booleans: read as a question. `isAvailable`, `hasConflict`
- Ballerina style: `camelCase` for functions/variables, `PascalCase` for
  types, `SCREAMING_CASE` for constants
- Proto style: `snake_case` fields, `PascalCase` messages — `bal grpc`
  converts `price_per_night` to `pricePerNight` automatically

No abbreviations nobody else knows. `prop` is fine, `pn` is not.

### Functions should do one thing

If a function is over ~30 lines or you can't name it without "and", split it.

```ballerina
// hard to test, hard to explain
function confirmBooking(...) { /* 80 lines of everything */ }

// each piece testable and explainable on its own
function isOverlapping(Booking existing, BookingRequest new) returns boolean
function calculateNights(string checkIn, string checkOut) returns int
function calculateCost(decimal rate, int nights) returns decimal
function confirmBooking(...) // orchestrates the three above
```

This one directly helps your defence — the examiner asks "how does overlap
work?" and you open a 6-line function instead of scrolling through 80.

### Magic numbers and strings

```ballerina
// bad
if nights > 30 { ... }

// good
const int MAX_BOOKING_NIGHTS = 30;
if nights > MAX_BOOKING_NIGHTS { ... }
```

---

## 10. Error handling — the professional bit

### Never swallow errors silently

```ballerina
// bad — the failure vanishes
Property? p = propertiesTable[id];

// good — the caller learns what went wrong
Property? p = propertiesTable[id];
if p is () {
    return error grpc:NotFoundError("No property with id: " + id);
}
```

### Validate at the boundary

Check inputs as they ENTER the service, not deep inside the logic.

```ballerina
remote function bookProperty(BookingRequest req) returns BookingResponse|error {
    // validate first, fail fast
    if req.checkOut <= req.checkIn {
        return error grpc:InvalidArgumentError("checkOut must be after checkIn");
    }
    if req.guestId.trim() == "" {
        return error grpc:InvalidArgumentError("guestId is required");
    }
    // ...now the real work, on data you trust
}
```

### Error messages are for humans

Bad: `"Error"`, `"failed"`, `"error code 3"`
Good: `"Property NUST-001 is already booked for 2026-09-10 to 2026-09-12"`

The examiner will deliberately send bad input. A clear message earns the
"error handling" marks; a stack trace does not.

### gRPC error types worth knowing

- `grpc:NotFoundError` — the id doesn't exist
- `grpc:InvalidArgumentError` — caller sent nonsense
- `grpc:AlreadyExistsError` — duplicate creation
- `grpc:InternalError` — genuinely our fault

Using the right one is a small detail that reads as competent.

---

## 11. Testing

### Ballerina has tests built in

```
question2-grpc/server/
  tests/
    booking_test.bal
```

```ballerina
import ballerina/test;

@test:Config {}
function testOverlapDetected() {
    Booking existing = {checkIn: "2026-09-10", checkOut: "2026-09-15", ...};
    BookingRequest incoming = {checkIn: "2026-09-12", checkOut: "2026-09-18", ...};
    test:assertTrue(isOverlapping(existing, incoming),
                    msg = "ranges 10-15 and 12-18 overlap");
}

@test:Config {}
function testBackToBackIsAllowed() {
    // checkout on the 15th, checkin on the 15th — NOT an overlap
    Booking existing = {checkIn: "2026-09-10", checkOut: "2026-09-15", ...};
    BookingRequest incoming = {checkIn: "2026-09-15", checkOut: "2026-09-18", ...};
    test:assertFalse(isOverlapping(existing, incoming));
}
```

Run: `bal test`

### Test the edges, not the happy path

The happy path works — you built it. Bugs live at boundaries:
- Same-day checkout/checkin (back-to-back)
- One range entirely inside another
- Identical dates
- checkOut before checkIn
- Booking a property that doesn't exist
- Confirming an empty cart
- Confirming twice

That is exactly P5's test matrix. Even 5 tests on the overlap logic is worth
writing — it's the highest-risk code in your slice, and "we wrote tests for
the booking conflicts" is a strong line in the presentation.

---

## 12. Documentation

### Comment WHY, not WHAT

```ballerina
// bad — restates the code
// increment counter
counter += 1;

// good — explains reasoning
// Half-open interval: a checkout and a checkin on the same day do not
// conflict, so the guest can leave and the next arrive same-day.
if newStart < existingEnd && newEnd > existingStart { ... }
```

### Doc comments on public functions

```ballerina
# Calculates total booking cost.
#
# + rate - price per night
# + nights - number of nights (checkOut - checkIn)
# + return - total cost
public function calculateCost(decimal rate, int nights) returns decimal {
```

Ballerina uses `#` for doc comments. `bal doc` generates HTML from them —
cheap points for professionalism.

### Your README must let a stranger run it

```markdown
## Running Q2

Prerequisites: Ballerina 2201.10.0

Terminal 1:  cd question2-grpc/server && bal run
Terminal 2:  cd question2-grpc/client && bal run

Regenerate stubs after editing the proto:
  bal grpc --input accommodation.proto --output server --mode service
```

Assume the marker has never seen your project and will not ask for help.

---

## 13. Working in a 5-person group

### Own your directory

You own `question2-grpc/`. Nobody else edits it. You don't edit theirs.
Directory ownership is the cheapest merge-conflict prevention there is.

### Pull before you start, every session

```bash
git checkout main && git pull
```

Skipping this is how you spend an hour resolving conflicts that didn't need
to exist.

### Agree contracts before code

P2/P3/P4 share the REST API, so the endpoint list and JSON shapes go in
`docs/api-contract.md` on day one. Then P3 builds against a stub while P2 is
still writing the service — nobody blocks.

Your proto is the same idea: it IS the contract between your server and
client. Get it right first, then both sides can proceed independently.

### Never force-push a shared branch

`git push --force` on `main` deletes other people's work. If you need it on
your own feature branch, use `--force-with-lease` — it refuses if someone
else pushed since you last fetched.

### Review each other's PRs

Even a two-minute read catches real bugs, and it means every member can
answer questions about the whole system during the defence — which you will
be asked to do.

---

## 14. Habits that separate good from average

**Compile after every meaningful change.** Finding out ten changes later that
something broke means bisecting ten changes.

**Commit working code only.** Broken commits poison `git bisect` and block
teammates. If you must save WIP, use your own branch.

**Read the error message.** Ballerina's compiler messages name the file, line
and the actual problem. Read it before you guess.

**Delete dead code.** Commented-out blocks are noise — git remembers it for
you. `// TODO: fix later` on 14 Sept means never.

**Consistent formatting.** Run `bal format` before committing. Zero effort,
and diffs stay about real changes instead of whitespace.

**Don't optimise what isn't slow.** In-memory tables for a demo will be
instant. Clarity beats cleverness — especially in code you must explain out
loud.

**If you can't explain it, don't ship it.** This is the real one. Anything in
your repo you can't defend live is a liability, not an asset.

