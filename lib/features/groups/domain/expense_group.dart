import 'group_member.dart';

class ExpenseGroup {
  const ExpenseGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.members = const [],
  });

  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final List<GroupMember> members;

  ExpenseGroup copyWith({String? name, List<GroupMember>? members}) {
    return ExpenseGroup(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      createdAt: createdAt,
      members: members ?? this.members,
    );
  }
}
