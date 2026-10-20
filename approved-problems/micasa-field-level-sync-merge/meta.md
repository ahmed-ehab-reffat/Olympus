---
Repository: https://github.com/micasa-dev/micasa
Issue: N/A
Commit: 0b0f92ae583bafc6242a3ed9dc756195d4162fb0
Language: Go
Category: feature-request
Title: Add field-level merging to micasa Pro sync conflicts
---

# Add field-level merging to micasa Pro sync conflicts

When two devices edit the same row between syncs, Pro sync should merge their edits field by field instead of letting one device's changes win outright.

We will compare data in each row with previous data from the last time this row was synced by the device. If data in a cell has changed only on one device, accept new data in the cell, even if it is blank. If data in a cell has changed on both devices, accept new data in that cell from the most recent change but do not mark cells with matching data on both devices as conflicts. Interval and due date fields for maintenance items count as one field. Status and resolution date fields for incidents count as one field. Data on both devices should match after a merge.

If one or more people remove a row, the full-row last-writer-wins rule applies, and all devices need to contain the winning row.

Logging a service for an item on one device updates its last service date on all devices. Clearing a field on a document on one device clears the field on all other devices.

Fields of a sync operation rejected in a merge are each listed as one conflict in sync results and in micasa pro conflicts, along with other incoming changes that lost an entire row, showing the field name and rejected value.
