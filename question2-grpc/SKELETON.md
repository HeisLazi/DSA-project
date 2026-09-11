# Skeleton Mode — how this works

The codebase is deliberately broken/incomplete. Your job: fix it,
understand every line you touch (live defence). YOU make all commits —
nothing here is committed for you; everything is currently untracked
local changes only.

The gate for each phase is a command that must go green. No green = no
commit (your call when) = no next phase. I hold the answer key — ask
for a hint, never the whole answer.

## The loop

    1. Read the BUG/ FIX comment in the file
    2. Fix it in VS Code
    3. Run the phase's gate command
    4. Green? -> commit it yourself (your call, your message) -> next bug
    5. Stuck? -> ask me. Hint, then nudge, then answer if you're truly dead.

## PHASE 1 — proto (gate: codegen passes)

File: question2-grpc/accommodation.proto

10 numbered BUG/FIX comments. Fix all 10, then:

    cd question2-grpc
    bal grpc --input accommodation.proto --output server --mode service
    bal grpc --input accommodation.proto --output client --mode client
    bal grpc --input accommodation.proto --output client

All three must succeed. Then DELETE these files:

    client/accommodationservice_client.bal   (collides with our own client)
    server/main.bal + client/main.bal        (hello-world noise; server must not have a main at all)

## PHASE 2 — store.bal (gate: bal build + bal test green)

File: question2-grpc/server/store.bal — 6 bugs (A-F).
File: question2-grpc/server/tests/store_test.bal — your compass, already written.

    cd question2-grpc/server
    bal build        # after each fix
    bal test         # 7 passing when done

## PHASE 3 — the 8 RPCs (gate: bal build green)

File: question2-grpc/server/accommodationservice_service.bal (generated, empty bodies).

You fill in the 8 bodies. I give you addProperty as a worked example ONCE
you reach this phase; the rest you write and I review. Key patterns are
all in store.bal already: nil-check with `is ()`, `check`,
`_ = remove(...)`, `lock { }`.

## PHASE 4 — client (gate: end-to-end demo)

File: question2-grpc/client/main.bal — write from scratch, I guide.

    terminal 1: cd question2-grpc/server && bal run
    terminal 2: cd question2-grpc/client && bal run

## PHASE 5 — polish

    bal format   (both packages)
    README section: how to run
    push + PR (you do this, when you're ready)

---

## Defence prep (do this as you go, not at the end)

After each phase, say out loud:
- WHAT the phase does
- WHY it's built that way (why a keyed table? why half-open overlap?)
- WHAT breaks if you remove the `lock`, the `check`, the `is ()` guard

If you can't answer, ask me — that's exactly the examiner's question.
