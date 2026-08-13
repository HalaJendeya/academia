import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';

class AdminBackButton extends StatelessWidget {
  const AdminBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.adminShell, (route) => false);
        }
      },
    );
  }
}
