import 'package:flutter/material.dart';

class GroupActionButtons extends StatelessWidget {
  final Function onManageLoans;
  final Function onManagePayments;
  final Function onEditGroupSettings;
  final Function onLogout;

  const GroupActionButtons({
    required this.onManageLoans,
    required this.onManagePayments,
    required this.onEditGroupSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on),
          label: 'Loans',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Payments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            onManageLoans();
            break;
          case 1:
            onManagePayments();
            break;
          case 2:
            onEditGroupSettings();
            break;
          case 3:
            onLogout();
            break;
        }
      },
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
    );
  }
}
