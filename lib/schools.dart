import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final List<Map<String, String>> schools = [
    {
      "title": "Komarovi",
      "image": "assets/komarovi.jfif",
      "url": "https://komarovi.edu.ge/ge",
    },
    {
      "title": "Vekua",
      "image": "assets/vekua42_logo.jfif",
      "url": "https://www.vekua42.edu.ge/",
    },
    {
      "title": "Newton",
      "image": "assets/Logo-newton-5.png",
      "url": "https://newton.edu.ge/",
    },
    {
      "title": "BGA",
      "image": "assets/british_georgian_academy_logo.jfif",
      "url": "https://bga.ge/",
    },
    {
      "title": "European School",
      "image": "assets/europeanschoollogo.png",
      "url": "https://europeanschool.ge/",
    },
    {
      "title": "New School",
      "image": "assets/newschool.png",
      "url": "https://newschoolgeorgia.com/",
    },
    {
      "title": "GAST",
      "image": "assets/georgian american school.jpg",
      "url": "https://gast.edu.ge/",
    },
    {
      "title": "QSI",
      "image": "assets/qsi.jpg",
      "url": "https://tbilisi.qsi.org/",
    },
  ];

  Future<void> launchWebsite(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'assets/opportunet1.png',
          height: 55,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: schools.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final school = schools[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => launchWebsite(school["url"]!),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black26,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                school["image"]!,
                                height: 80,
                                width: 80,
                              ),
                            ),
                            Text(
                              school["title"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xff84d6fe),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff84d6fe),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                "Open",
                                style: TextStyle(
                                  color: Colors.black,
                                  
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
