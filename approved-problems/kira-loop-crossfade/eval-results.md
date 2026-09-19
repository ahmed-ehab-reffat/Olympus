# eval-results.md — kira-loop-crossfade

| Batch | Run | Agent | Verdict | Msgs | Files | LOC | Failed tests | Failure reason | Approach note |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 16 | +480 | streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights | frame 47: 47 exact old-loop frames then 0.0 (decoder gate still closed) | ARTIFACT: passes 55/55 with the prefix lowered to 12 |
| 1 | 2 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 17 | +408 | streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights | frame 24: 24 exact old-loop frames then silence | ARTIFACT: passes 55/55 with the prefix lowered to 12 |
| 1 | 3 | Nova | PASS | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 16 | +590 | - | - | reference-like scheduler, head frames kept per pass |
| 1 | 4 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 17 | +516 | streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights | frame 47 underrun | ARTIFACT: passes 55/55 with the prefix lowered to 12 |
| 1 | 5 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 18 | +500 | streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights | frame 47 underrun | ARTIFACT: eager prepare_crossfade of tail+head; passes 55/55 with the prefix lowered to 12 |
| 1 | 6 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 18 | +525 | set_loop_region_mid_pass_uses_the_new_weights_and_clamp | GENUINE: live switch to loop 9..11 left the position past the new end; wrap subtracts the full loop once then adds the fade once instead of repeatedly stepping by (loop - fade) | still fails after the prefix fix |
| 1 | 7 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 18 | +490 | streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights | frame 47 underrun | ARTIFACT: pending-crossfade state; passes 55/55 with the prefix lowered to 12 |
| 1 | 8 | Nova | PASS | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 18 | +538 | - | - | - |
| 1 | 9 | Nova | PASS | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 17 | +510 | - | - | - |
| 1 | 10 | Nova | FAIL | n/a (trajectory steps truncated; prompt tokens 3.9M-8.7M) | 18 | +505 | streaming_set_loop_region_keeps_the_buffered_audio_then_uses_new_weights | frame 47 underrun | ARTIFACT: clears crossfade frames on region change; passes 55/55 with the prefix lowered to 12 |

Batch 1 (accepted): 3/10 Nova, every failing run 54/55. Replaying each failing agent patch with the
region test's buffered prefix lowered from 48 to 12 frames (queue-depth-independent): runs 1, 2, 4, 5,
7 and 10 pass 55/55; run 6 still fails the live short-region clamp; pass run 3 stays 55/55. Genuine
pass rate on a fair suite: 9/10. The platform Auto Review flagged the fixed 48 as a Medium false
negative after the batch.
