import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';

/// Shared "resolve the active group, then route" logic used right after a
/// user is known to be authenticated — from the splash screen as well as
/// right after a successful login/register.
///
/// Behavior:
/// - fetches the user's groups and tries to restore a previously-selected
///   group;
/// - if a group is (still) selected, goes to `/dashboard`;
/// - else if the user belongs to exactly one group, auto-selects it and
///   goes to `/dashboard`;
/// - otherwise (zero or multiple groups with no valid restored selection),
///   goes to `/group-select` so the user can choose or create/join one.
Future<void> resolveGroupAndRoute(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final groupProvider = context.read<GroupProvider>();
  final token = auth.token!;

  await groupProvider.fetchMyGroups(token);
  await groupProvider.restoreSelection(token);
  if (!context.mounted) return;

  if (groupProvider.currentGroup != null) {
    Navigator.pushReplacementNamed(context, '/dashboard');
    return;
  }

  if (groupProvider.myGroups.length == 1) {
    await groupProvider.selectGroup(token, groupProvider.myGroups.first);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
    return;
  }

  Navigator.pushReplacementNamed(context, '/group-select');
}
