---
Repository: https://github.com/micasa-dev/micasa
Issue: N/A
Commit: ca69a88f998dec25c1e285121e428a4f7621dc68
Language: Go
Category: feature-request
Title: Add relay storage reclaim to micasa Pro sync
---

# Add relay storage reclaim to micasa Pro sync

We want to enable micasa Pro users to free up relay storage space used by document files that no device in their home uses anymore. micasa Pro users who upload updated documents cannot remove previous versions of uploaded documents from relay storage. Previous versions of documents use relay storage space that other users in the home may need.

After each successful sync, the device sends information to the relay about which files are used by the device's documents. Files linked to deleted documents are reported to allow users to restore documents. Files not yet downloaded to the device are reported. A device may have more documents than can fit in a single request, and the relay keeps its 1 MB limit on request body size, so all of a device's documents must be reported. Reporting shouldn't get expensive for devices with lots of documents either: once a device has reported, a later sync where only one of its documents changed must send and receive less than 64 KB in total, even on a device with 20,000 documents.

`micasa pro storage --reclaim` first syncs, then instructs the relay to remove files stored for the household that are not mentioned in the latest report of any household device. Output includes `removed N files, freed SIZE` and the usual `micasa pro storage` information about new storage use by the household. The same units are used to report file sizes as in `micasa pro storage`. The relay should not delete any files if there are one or more devices in the household that have not sent a report to the relay since the last change they pushed to it. Devices that have never sent a report are not excluded. If one or more such devices are present, `micasa pro storage --reclaim` outputs `waiting for: ` followed by a comma-separated list of their device names and otherwise takes no action to delete files. Revoked devices are not included. If no devices are listed as waiting, the reclaim command also uploads to the relay any file of the device's documents that the relay is missing. These may include files previously rejected by the relay for lack of space for the household, which other household devices can then access. They may also belong to documents that have been deleted. Space used by these uploads is reported by `micasa pro storage --reclaim`.

Replacing the file of a document on one device: other devices should be able to access the newly uploaded file after they synchronize.
