# Q2 gRPC — Day-by-Day Plan (owner: Lazi)

Deadline: Mon 14 Sept 2026, 23:59. No late commits accepted.
Marks: proto 15 / server 25 / client 10.

## Competing commitments
- TenderOS port — due Monday 8 Sept (work, hard)
- Mom's project — ongoing
- Revision — ongoing
- Sat 5 Sept — busy most of the day, free afternoon onwards
- Free time is a requirement, not a luxury. Burnout on 10 Sept loses more
  marks than a slow day on 6 Sept.

## Shape of the plan
The first three days are deliberately light because TenderOS owns them.
Real gRPC work starts Mon 8 Sept once TenderOS ships. Fri 12 Sept is the
target finish; the weekend is buffer, not plan.

---

### Fri 4 Sept (today) — 30 min  [DONE]
- [x] Ballerina installed, repo cloned, packages scaffolded
- [x] Tutorial + roadmap written
- [ ] Read tutorial §1-2 (proto syntax + 4 RPC types) — 15 min
- [ ] Send the group the work split + push for `docs/api-contract.md`

### Sat 5 Sept — 1 hr, afternoon/evening only
Busy most of the day. Low-effort, high-value only.
- [ ] Write `accommodation.proto`: header, enums, messages
- [ ] Do NOT write the service block yet
Stop when messages are done. This is a reading/typing task, not a thinking one.

### Sun 6 Sept — 1.5 hrs
- [ ] Add the 8 RPCs to the service block
- [ ] `bal grpc` generates without error
- [ ] Commit: `feat(grpc): define proto contract with 8 RPCs`
**Milestone: 15 marks effectively banked.**
Rest of the day: TenderOS + revision.

### Mon 7 Sept — 0 hrs on DSA
TenderOS port ships today. Protect it. No context switching.

### Tue 8 Sept — 2.5 hrs
First real build day.
- [ ] `types.bal` — your own records
- [ ] `store.bal` — three tables + booking cart map + seed data
- [ ] `bal build` passes
- [ ] Commit: `feat(server): add in-memory data store`

### Wed 9 Sept — 2.5 hrs
- [ ] addProperty, searchProperty, updateProperty
- [ ] removeProperty (returns host's REGIONAL list — re-read the brief)
- [ ] Commit each RPC separately
**Milestone: all 4 simple RPCs done.**

### Thu 10 Sept — 2.5 hrs
The two that carry the streaming marks.
- [ ] listAvailableProperties — server streaming + location/price filter
- [ ] createUsers — client streaming, one confirmation at the end
- [ ] Commit: `feat(server): add streaming RPCs`

### Fri 11 Sept — 3 hrs
Hardest day. Do it when fresh, not at midnight.
- [ ] bookProperty — validate checkOut > checkIn, push to cart
- [ ] `isOverlapping()` as its own small function
- [ ] confirmBooking — overlap check, cost = rate x nights, clear cart
- [ ] 3-5 tests in `tests/booking_test.bal`, `bal test` green
- [ ] Commit: `feat(booking): add cart and overlap-checked confirmation`
**Milestone: server complete, 25 marks in place.**

### Sat 12 Sept — 3 hrs
- [ ] CLI client: menu loop, all 8 operations
- [ ] Consume server stream in a loop; feed client stream then close
- [ ] Errors print as messages, not stack traces
- [ ] Full end-to-end run: server terminal + client terminal
- [ ] Commit: `feat(client): add interactive gRPC client`
**Milestone: feature-complete. Everything after this is polish.**

### Sun 13 Sept — 2 hrs
- [ ] `isolated` + `lock` on shared state (the "concurrent requests" requirement)
- [ ] `bal format`, delete dead code
- [ ] README: how to run, proto explanation, design decisions
- [ ] Demo script — the exact click-by-click sequence
- [ ] Rehearse out loud: why each streaming type, how overlap works
- [ ] Push everything, confirm PRs merged

### Mon 14 Sept — buffer only
Submission day. Do not plan work here.
- [ ] Final `git pull`, verify main builds clean
- [ ] Confirm all 5 members show as contributors
- [ ] Submit repo link on eLearning EARLY, not at 23:00

---

## Total: ~18 hrs across 10 days, front-loaded away from TenderOS

## If a day slips
Skip in this order: tests -> polish -> filters on listAvailable.
NEVER skip: the proto, confirmBooking, or the client. Those are 50 of 50.

## Daily habit (5 min)
Start: `git checkout main && git pull`
End: commit working code, update the checkbox above.
