import 'package:flutter/material.dart';

import 'twitter_post_composer.dart';

/// Anket paylaşımı — tam sayfa route (dialog/sheet çakışması yok).
class PollPostPage extends StatelessWidget {
  final String? userEmail;

  const PollPostPage({super.key, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Anket Paylaş',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: TwitterPostComposer(
            userEmail: userEmail,
            startInPollMode: true,
          ),
        ),
      ),
    );
  }
}
