---
Repository: https://github.com/pyeventsourcing/eventsourcing
Issue: N/A
Commit: 575d42c10a821828639b90178ed56703abe9c9f1
Language: Python
Category: feature-request
Title: Add consistent cuts and forks to event processing systems
---

# Add consistent cuts and forks to event processing systems

Add system runner support for consistent cuts, so a system of running applications can be read or forked off as it was at one consistent point.

Every runner provides a `cut(bounds=None)` method, where `bounds` is a dictionary mapping application names to notification ids. Unknown names and negative ids raise `ValueError`. The returned cut has `positions`, which is a dictionary mapping all application names in the system to notification ids as of the cut (0 if none), and `processed`, which is a dictionary mapping every follower to the maximum notification id it had processed at the cut from each of its leaders (also 0 if none). The cut also has a `get(cls, aggregate_id)` method that returns the aggregate of application class `cls` as of the cut, or raises `AggregateNotFoundError` if it did not exist yet.

Processing one leader event is a step, even if it doesn't change the application state in any way according to policy, and each save of new events outside of leader processing is a step too. For each application, the cut keeps the longest prefix of steps in which no recorded event has a notification id above that application's bound, and no processed leader event has an id above the leader's own position in the cut. The application's position in the cut is the highest notification id among the events it keeps. If followers are cyclic, we choose the greatest such cut.

The cut's `fork(env=None)` method creates a new, started runner of the same type, initialized with `env`, that holds exactly the state at the cut: every event the cut keeps, under its original notification ID, and followers with the same processed positions as in the cut. Some recorders keep extra data beside the events, like a search index built from each save's keyword arguments, and the fork holds that data as it was at the cut too. Cutting the fork gives the same results as cutting the original runner with the fork's bounds added in. New events in the fork are processed by its followers from where the cut left them. `fork` raises `ValueError` if any application in `env` already has events. A runner reopened on the same SQLite databases must make the same cuts, even after it records more. Only the in-memory and SQLite persistence modules need to support cuts and forks.
