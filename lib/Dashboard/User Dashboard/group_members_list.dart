import 'package:flutter/material.dart';
import 'member_list_tile.dart'; // Custom widget for member list

class GroupMembersList extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  GroupMembersList({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(child: Text('No members found.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final member = members[index];
        return MemberListTile(
          name: member['name'] ?? 'Unnamed',
          profilePictureUrl: member['profilePicture'],
          memberId: member['userId'],
        );
      },
    );
  }
}
