import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    setState(() {
      _hasPermission = result.isAuth;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sweep needs acess to your photos.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Grant Access'),
              ),
            ],
          ),
        ),
      );
    }
    
    return const Scaffold(
      body: Center(
        child: Text('Photos loaded soon.'),
      ),
    );
  }
}