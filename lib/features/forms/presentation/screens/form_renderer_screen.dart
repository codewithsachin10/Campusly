import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FormRendererScreen extends StatelessWidget {
  final String formToken;

  const FormRendererScreen({Key? key, required this.formToken})
      : super(key: key);

  void _openWebForm() async {
    // Attempt to open the web form in a browser
    // Assuming backend is at https://campusly.app/form/:token 
    // but for local testing you can use your ngrok or local ip
    final url = Uri.parse('http://10.0.2.2:8080/form/$formToken');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campusly Forms'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Student Form',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Form Token: $formToken',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openWebForm,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Form in Browser'),
            ),
          ],
        ),
      ),
    );
  }
}
