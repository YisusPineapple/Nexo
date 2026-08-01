import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index into HomeShell's destination list (Songs=0 ... Playlists=5).
/// Plain StateProvider — no persistence, no business logic, just
/// "which tab is displayed" during the lifetime of the widget tree.
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);