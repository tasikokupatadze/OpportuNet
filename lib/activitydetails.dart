import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  Future<void> _launchWebsite(String website) async {
    final Uri url = Uri.parse(website);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = activity["title"] ?? "";

    final description = activity["description"] ?? "";
    final website = activity["website"] ?? "";
    final age = activity["ageRequirements"] ?? "Not specified";
    final cost = activity["cost"] ?? "Not specified";
    final imageUrl = activity["imageUrl"] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/opportunet1.png',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                color: Color(0xff84d6fe),
                child: const Icon(Icons.image, size: 80),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff84d6fe),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Description",
                    style: TextStyle(
                      color: Color(0xff84d6fe),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(description),
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text(
                      "Age Requirements",
                      style: TextStyle(
                        color: Color(0xff84d6fe),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(age),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text(
                      "Cost",
                      style: TextStyle(
                        color: Color(0xff84d6fe),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(cost),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: website.isEmpty
                          ? null
                          : () => _launchWebsite(website),
                      icon: const Icon(Icons.open_in_new, color: Colors.black),
                      label: const Text(
                        "Visit Website",
                        style: TextStyle(
                          color: Color(0xff84d6fe),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
