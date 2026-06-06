import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VlntrScreen extends StatefulWidget {
  const VlntrScreen({super.key});

  @override
  State<VlntrScreen> createState() => _VlntrScreenState();
}

class _VlntrScreenState extends State<VlntrScreen> {
  final List<Map<String, String>> volunteering = [
    {
      "title": "Helping Hand",
      "image": "assets/helping hand.jfif",
      "url": "https://youthvolunteering.ge/",
    },
    {
      "title": "Caritas Georgia",
      "image": "assets/caritas.webp",
      "url": "https://caritas.ge/",
    },
    {
      "title": "volunteers.ge",
      "image": "assets/volunteers ge.png",
      "url": "https://volunteers.ge/",
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
      body: SingleChildScrollView(
        child: Column(
          children: [
               GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: volunteering.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final vlntr = volunteering[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => launchWebsite(vlntr["url"]!),
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
                                vlntr["image"]!,
                                height: 80,
                                width: 80,
                              ),
                            ),
                            Text(
                              vlntr["title"]!,
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
            
            const SizedBox(height: 8),
              const Text(
                  "If none of these organizations seem appealing, here's a list of some places to consider volunteering:",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Local Libraries: Volunteer to help with organizing books, assisting in reading programs for kids, or running community events.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Food Banks and Soup Kitchens: Assist with meal preparation, distribution, and organizing food drives.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Homeless Shelters: Offer your time to help with daily operations, provide support services, or organize donation drives.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Community Gardens: Help with planting, maintaining, and harvesting gardens that supply fresh produce to local communities",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Animal Shelters: Volunteer to care for animals, assist with adoptions, or help with shelter maintenance.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Local Festivals and Fairs: Assist with organizing, setting up, and running community events.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Graphic Design for Nonprofits: Offer your design skills to create promotional materials for non-profits.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Community Theaters: Help with set design, costumes, or backstage work during performances",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              const Text(
                  "• Start a Community Initiative: Identify a need in your community and create a project to address it, such as a recycling program, community garden, or neighborhood watch group.",
                  style: TextStyle(
                    color: Color(0xff84d6fe),
                    fontSize: 14,
                  )),
          ],
        ),
      ),
    );
  }
}
