/// In-memory holder for the currently-selected duty group's id.
///
/// `GroupProvider` is the only writer of this value (see
/// `lib/providers/group_provider.dart`). Every group-scoped `ApiService`
/// call reads it to attach the `X-Group-Id` header.
class GroupSession {
  static String? currentGroupId;
}
