import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OlympScreen extends StatefulWidget {
  const OlympScreen({super.key});

  @override
  State<OlympScreen> createState() => _OlympScreenState();
}

class _OlympScreenState extends State<OlympScreen> {
  final List<Map<String, String>> olympiads = [
    {
      "title": "Euler Olympiad",
      "image": "assets/FreeUniLogo.png",
      "url": "https://freeuni.edu.ge/ge/freshmen/contests/euler-olympics/",
    },
    {
      "title": "Kangaroo",
      "image": "assets/kenguru.png",
      "url": "https://kenguru.ge/about",
    },
    {
      "title": "NAEC Olympiads",
      "image": "assets/naec.png",
      "url": "https://www.naec.ge/#/ge/posts/byCategory/516",
    },
    {
      "title": "Moazrovne",
      "image": "assets/moazrovne.png",
      "url": "https://www.moazrovne.edu.ge/moazrovne",
    },
    {
      "title": "Leonardo Da Vinci",
      "image": "assets/davincilogo.jpg",
      "url":
          "https://rustaveli.org.ge/geo/siakhleebi/fondi-atskhadebs-2026-tslis-mostsavle-gamomgonebelta-da-mkvlevarta-konkurss-leonardo-da-vinchi",
    },
    {
      "title": "Millennium Innovation",
      "image": "assets/milleniumlogo.png",
      "url":
          "https://millennium.org.ge/geo/news/2026-%E1%83%AC%E1%83%9A%E1%83%98%E1%83%A1-%E1%83%90%E1%83%97%E1%83%90%E1%83%A1%E1%83%AC%E1%83%9A%E1%83%94%E1%83%A3%E1%83%9A%E1%83%98%E1%83%A1-%E1%83%98%E1%83%9C%E1%83%9D%E1%83%95%E1%83%90%E1%83%AA%E1%83%98%E1%83%98%E1%83%A1-%E1%83%99%E1%83%9D%E1%83%9C%E1%83%99%E1%83%A3%E1%83%A0%E1%83%A1%E1%83%98-%E1%83%92%E1%83%90%E1%83%9B%E1%83%9D%E1%83%AA%E1%83%AE%E1%83%90%E1%83%93%E1%83%93%E1%83%90/73",
    },
    {
      "title": "Technovation",
      "image": "assets/techgirls.jpg",
      "url": "https://technovationchallenge.org/",
    },
    {
      "title": "GENIUS Olympiad",
      "image": "assets/genius.png",
      "url": "https://geniusolympiad.org/",
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
                itemCount: olympiads.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final olymp = olympiads[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => launchWebsite(olymp["url"]!),
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
                                olymp["image"]!,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Text(
                              olymp["title"]!,
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
            
            const Text(
              "Winning these Olympiads or contests can lead to competing internationally (IMO, IPhO, ISEF, etc.)",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xff84d6fe),
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
