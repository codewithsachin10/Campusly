import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class FormRendererScreen extends StatelessWidget {
  final String formToken;

  const FormRendererScreen({super.key, required this.formToken});

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
        title: Text('Campusly Forms'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 80, color: Colors.blue),
              SizedBox(height: 16.h),
              Text(
                'Student Form',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Form Token: $formToken',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: _openWebForm,
                icon: Icon(Icons.open_in_browser),
                label: Text('Open Form in Browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
