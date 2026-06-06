import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExchPrgrmScreen extends StatefulWidget {
  const ExchPrgrmScreen({super.key});

  @override
  State<ExchPrgrmScreen> createState() => _ExchPrgrmScreenState();
}

class _ExchPrgrmScreenState extends State<ExchPrgrmScreen> {
  final List<Map<String, String>> exchPrgms = [
    {
      "title": "FLEX",
      "image": "assets/flex.png",
      "url": "https://www.discoverflex.org/",
    },
    {
      "title": "Erasmus+",
      "image": "assets/eu.webp",
      "url": "https://erasmus-plus.ec.europa.eu/",
    },
    {
      "title": "UWC",
      "image": "assets/uwc.png",
      "url": "https://www.uwc.org/",
    },
    {
      "title": "WTP",
      "image": "assets/mit.png",
      "url": "https://wtp.mit.edu/",
    },
    {
      "title": "SUMAC",
      "image": "assets/stanford.png",
      "url": "https://sumac.spcs.stanford.edu/",
    },
    {
      "title": "YYGS",
      "image": "assets/yale.png",
      "url": "https://globalscholars.yale.edu/",
    },
    {
      "title": "VSA",
      "image": "assets/vanderbilt.png",
      "url": "https://pty.vanderbilt.edu/for-students/vsa/",
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
                itemCount: exchPrgms.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final exch = exchPrgms[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => launchWebsite(exch["url"]!),
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
                                exch["image"]!,
                                height: 80,
                                width: 80,
                              ),
                            ),
                            Text(
                              exch["title"]!,
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
            
            TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse("https://www.snow.day/");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Column(
                  children: [
                    SizedBox(height: 8),
                    Text("For more programs click here",
                        style: TextStyle(
                          color: Color(0xff84d6fe),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ))
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
