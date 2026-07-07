import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the active tab index inside [MainShell].
/// Switch tabs from anywhere:
///   ref.read(activeTabProvider.notifier).setTab(2); // jump to Weton
class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(
  ActiveTabNotifier.new,
);
