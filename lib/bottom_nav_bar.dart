import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 32),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search, size: 32),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.compare_arrows_outlined, size: 32),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wallet, size: 32),
          label: '',
        ),
      ],
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
    );
  }
}
