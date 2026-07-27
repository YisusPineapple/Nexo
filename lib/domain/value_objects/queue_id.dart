// Identifies one of the up to five concurrent playback queues
// (REPRODUCCIÓN §2: "Multiples colas de reproducción"). Needed so the
// presentation layer and future PlaybackRepository can address
// "queue #3" directly, instead of relying on list position — which
// would break as soon as a queue is closed or reordered.
extension type const QueueId(String value) {}
