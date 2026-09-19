---
Repository: https://github.com/hanruihua/ir-sim
Issue: N/A
Commit: e4a60f94bb719f60a615d98025db4ed7b882f6cf
Language: Python
Category: feature-request
Title: Add declarative scenario events to the simulation step loop
---

# Add declarative scenario events to the simulation step loop

Add an `events` section to the world YAML so a scenario can change itself while it runs.

`events` is a list. Each event has a `when` condition and a `do` list of actions (or one action), plus optional `name` (default `event_<index>`, counting every event from 0), `repeat` (default false), and `cooldown` and `delay`, both in steps, defaulting to 1 and 0. An `events` value that is not a list, an unknown key in an event, condition, action or spawned object's mapping, or an event without `when` or `do` makes creating the environment raise `ValueError`.

Conditions are mappings with one key. `time: t` holds once the environment time is at least t. `arrive: <name>` and `collision: <name>` hold while that object has arrived or is colliding. `distance: {objects: [a, b], below: d}` holds while their centres are closer than d. `enter: {object: <name>, region: [xmin, ymin, xmax, ymax]}` holds when the object's centre is inside that closed rectangle but was outside at the previous check, whether or not that check evaluated this condition, and `leave` is the reverse; an object that was not there at the previous check neither enters nor leaves, and a reset counts as a check. `all`, `any` and `not` combine conditions. A condition about a missing object is false.

Events are checked at the end of every step that advances the simulation, after collisions and arrivals are updated. Due delayed actions run first, in the order they were scheduled; then the events are checked in the order listed, each seeing what the ones before it did. An event fires at a check where its condition holds: without `repeat` only once, with `repeat` again once at least `cooldown` steps have passed since it last fired. With `delay` d, the actions run at the check d steps after firing. Each run of an event's actions appends `(time, name)` to `env.event_log`.

`spawn: {robot: {...}}` or `spawn: {obstacle: {...}}` creates objects from a mapping with the keys of a `robot` or `obstacle` entry. They get the next ids and go at the end of `env.objects`; when the mapping has a `name`, each event numbers its spawns `<name>_1`, `<name>_2` and so on. `delete: <name>` removes that object if present, `goal: {object: <name>, goal: [x, y, theta]}` sets its goal, and `pause: true` pauses the environment once the check is over. Everything the environment does, including collisions, sensors, behaviors, `done()` and lookups, sees spawned and deleted objects accordingly.

`reset()` undoes what events did to the scene: spawned objects go, and each deleted object comes back with its id, name and place in `env.objects`, at its initial state. Objects added with `add_object` stay. Every event starts over as if new, pending delayed actions are dropped and the log is emptied, so running the same steps again gives the same log, names and ids. `reset(random=True)` and `reload()` start the events over too; `reload()` takes them from the reloaded file.
