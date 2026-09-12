# Solution approach - failure-atomic remote offers

## Transaction boundary

`SdpApi::accept_offer` previously validated and committed one subsystem at a
time. It invalidated the outstanding local offer, applied ICE details, installed
the first fingerprint, initialized DTLS and SCTP state, and then applied session
and media changes. A late m-line ordering error could therefore return
`RtcError::RemoteSdp` after earlier state had already changed.

The solution keeps the documented change-ID invalidation at the start of the
method and introduces an immutable preflight before every other mutation. This
is the required compatibility boundary: a remote offer always supersedes a
pending local offer, but a rejected remote offer commits nothing else.

## Offer preflight

`validate_offer` checks the offer-wide conditions that can reject
`accept_offer`:

- at least one m-line;
- the existing ICE-Lite pairing restriction;
- SDP consistency;
- complete ICE credentials;
- a fingerprint when the receiver has not established one;
- established SNAP `a=sctp-init` consistency; and
- the complete prospective m-line layout.

The media preflight walks all lines through immutable session state. It verifies
that existing MIDs remain at their established indexes, that application-line
occupancy stays compatible, and that an unknown MID can replace an occupied
index only when the old media is stopped. New lines are collected for the later
commit without touching media, streams, codec mappings, extension mappings, or
event flags.

## Commit

After preflight succeeds, `accept_offer` retains the existing successful order:
ICE details and restarts, first fingerprint, ICE/DTLS role setup, accepted SNAP
state, session/media changes, SCTP initialization, and answer rendering.

Offer media are committed by `sync_offer_medias`, which first repeats the
immutable layout check and then performs an infallible update pass. Existing
media are updated, valid stopped slots are retired, and the already-discovered
new lines are returned to the existing creation path.

The answer path deliberately remains separate. `sync_answer_medias` preserves
the original incremental `accept_answer` behavior, keeping this task limited to
remote offers.

## SCTP validation

The established-SNAP comparison was separated into
`validate_remote_sctp_init`. The mutating `process_remote_sctp_init` calls it
before caching or decoding new state, while offer preflight can call the same
logic immutably. This preserves the existing changed/missing error
classification and the existing behavior for non-SNAP associations.

## Verification

The public integration suite covers:

1. an early media direction change and event polling followed by a late
   reordered-MID rejection;
2. remote extension-map changes combined with the same late rejection;
3. an ICE restart combined with that late rejection and a valid retry;
4. remote candidate installation before that late rejection;
5. a missing initial fingerprint followed by a valid retry, with the
   different-peer fingerprint handshake and pending-offer invalidation checks
   executed in the same base-failing test; and
6. an established SNAP rejection combined with ICE/media changes and retry.

All six tests fail on the pinned base for the intended atomicity defects and
pass with the solution. The event, fingerprint, and pending-offer compatibility
assertions remain covered without appearing as standalone base-passing tests.
The 31 neighboring SDP tests and the full portable-backend suite also pass.
