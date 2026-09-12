---
Repository: https://github.com/asticode/go-astits
Language: Go
Issue: stream-analyzer
Commit: 5fcd7d85573d2d8330c01b0e98cba71149732b09
Title: Add a transport stream analyzer to the demuxer
---

# Add a transport stream analyzer to the demuxer

Add an `Analyzer` reporting stream anomalies and per-PID statistics. `NewAnalyzer(o AnalyzerOptions) *Analyzer` builds one, `Packet(p *Packet)` and `Data(d *DemuxerData)` feed packets and parsed units in stream order, `Report() *AnalyzerReport` reports everything fed so far and may be called repeatedly, and a nil packet or data unit is ignored.

`DemuxerOptAnalyzer(a *Analyzer) func(*Demuxer)` makes a demuxer feed both, `MuxerOptAnalyzer(a *Analyzer) func(*Muxer)` makes a muxer feed the packets it builds for `WriteData` and those passed to `WritePacket`, but not the table bytes `WriteTables` emits nor a packet whose write fails, and `AnalyzeStream(ctx context.Context, r io.Reader, o AnalyzerOptions) (*AnalyzerReport, error)` demuxes a reader and reports, treating `ErrNoMorePackets` or any error wrapping `io.EOF` as the end even when no packet was read, and returning any other error. `AnalyzerOptions` holds `time.Duration` fields `MaxPATInterval`, `MaxPCRInterval` and `MaxPMTInterval`, a non-positive one meaning 500ms, 40ms and 500ms. Packets are indexed from zero as fed.

Time counts 27 MHz ticks wrapping at `1<<33` times 300, elapsed is the signed representative from minus half that wrap up to but excluding plus half, so exactly half reads as backwards, and a duration is nanoseconds times 27 divided by 1000. The first packet carrying a PCR fixes the reference PID, only PCRs there move the clock, and its own PCR times it. Each later reference PCR closes a window: an inner packet is timed by adding to the opening tick the elapsed value times its index distance from the opening packet, integer-divided by the distance between both PCRs.

A window is regular only when its closing packet carries no discontinuity indicator and its elapsed value is positive and at most `MaxPCRInterval`; otherwise its inner packets, though not that closing PCR, have unknown time, written -1, as do packets before the first reference PCR and those still waiting at `Report`, which fixes them as unknown for good. A closing PCR not strictly later than the previous one raises `AnalyzerEventKindPCRDiscontinuityError`, one later than `MaxPCRInterval` raises `AnalyzerEventKindPCRRepetitionError`, and a discontinuity indicator suppresses both.

A set transport error indicator raises `AnalyzerEventKindTransportError` carrying its packet's time, counts toward its PID's packets, and is ignored by everything else. A PID is known when it is at most 0x1f, the null PID, a program map PID a PAT names, or a PCR or elementary PID a PMT names, always judged from the tables read so far, a later table for the same program replaces its map, PCR and elementary PIDs, a program a later table omits is kept, and a PID any table has already named keeps that role; the first packet on an unknown PID raises `AnalyzerEventKindUnreferencedPID`, once per PID. A PAT entry numbered 0 is ignored entirely, creating no program and leaving its PID unknown.

A non-zero scrambling control counts as scrambled and, on PID 0, the null PID or a program map PID, raises `AnalyzerEventKindScramblingError`.

Continuity skips the null PID. A PID's first packet, or one carrying a discontinuity indicator, only records the counter. Otherwise the expected counter is the previous plus one modulo 16 with a payload and the previous unchanged without one, while a packet with a payload repeating the previous counter is a legal duplicate unless the packet before it was itself a legal duplicate, so a run of one counter alternates between legal repeats and reported ones. Anything else raises `AnalyzerEventKindContinuityError` carrying `Expected` and `Actual`, left zero on other kinds.

A payload unit start on PID 0 or a program map PID, duplicates aside, is a table occurrence; one more than `MaxPATInterval` or `MaxPMTInterval` after the previous occurrence raises `AnalyzerEventKindPATRepetitionError` or `AnalyzerEventKindPMTRepetitionError`, and an occurrence of unknown time is neither measured nor compared against, but still replaces the previous one.

Presentation timestamps wrap at `1<<33` and compare by that same signed representative at their own wrap: on parsed stream data one not strictly later than the previous on that PID raises `AnalyzerEventKindPTSOrderError`, and a decoding timestamp later than its own presentation timestamp raises `AnalyzerEventKindDTSOrderError`, both attributed to the last packet fed.

`AnalyzerReport` holds `Packets int`, `Events []AnalyzerEvent` ordered by packet index then by kind as transport, unreferenced, scrambling, continuity, PCR discontinuity, PCR repetition, PAT repetition, PMT repetition, PTS order, DTS order, `PIDs []AnalyzerPIDStat` ordered by PID, and `Programs []AnalyzerProgram` ordered by number, each of those three a slice holding its elements by value.

An `AnalyzerEvent` holds `Kind AnalyzerEventKind`, `PID uint16`, `PacketIndex int`, `Time int64`, `Expected uint8` and `Actual uint8`, where `Time` is the time of the packet reported on, or -1 when it has none. An `AnalyzerProgram` holds `Number uint16`, `PMTPID uint16`, `PCRPID uint16`, ascending deduplicated `ElementaryPIDs []uint16`, and the `MissingPIDs []uint16` among them that carried no packet, an errored packet counting as carried.

An `AnalyzerPIDStat` holds `PID uint16`, the `int` counters `Packets`, `ScrambledPackets`, `PayloadBytes`, `ContinuityErrors`, `Discontinuities` and `PCRs`, and the `int64` values `FirstTime`, `LastTime`, the `MinPCRInterval` and `MaxPCRInterval` elapsed between consecutive PCRs of that PID, and `Bitrate`, one less than its number of timed packets, times 1504 times 27000000, divided by their span. `FirstTime` and `LastTime` are the first and last of those times or -1, the intervals -1 below two PCRs, and `Bitrate` zero below two.
