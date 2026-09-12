Title: Fix partial state updates after rejected remote SDP offers

Fix a bug in `SdpApi::accept_offer` where rejecting a parsed remote offer with `RtcError::RemoteSdp` can leave remote-negotiated state partially applied. The receiver must instead retain the remote-negotiated state it had before the call, and pending media events must not reflect the rejected offer.

An `Rtc` that was alive before the call must remain usable. In particular, an invalid initial offer such as one without a fingerprint must return an error without disconnecting the receiver, and a later valid offer must behave as if the rejected offer had never been applied.

Preserve the documented glare behavior: calling `accept_offer` still invalidates an outstanding `SdpPendingOffer`, even when the incoming offer is rejected. This task covers rejection of remote offers in `accept_offer`; it does not change SDP parsing or `accept_answer`.
