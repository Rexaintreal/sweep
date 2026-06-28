import 'package:flutter/material.dart';

class ClarificationScreen extends StatelessWidget {
  const ClarificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CLARIFICATION',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.cloud_off_outlined,
                size: 64,
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Why can\'t Sweep delete files from cloud backup?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Sweep works on local photos and videos only. If you back up pictures to Google Photos or another cloud service, the media will not be deleted from the cloud backup.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Due to platform limitations, pictures can only be deleted from your device storage.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Okay, I understand'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}