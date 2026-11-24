import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import 'volunteeringdetails.dart';
import 'activitydetails.dart';

class VlntrScreen extends StatefulWidget {
  const VlntrScreen({super.key});

  @override
  State<VlntrScreen> createState() => _VlntrScreenState();
}

class _VlntrScreenState extends State<VlntrScreen> {
  bool _isOrganizer = false;

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      _isOrganizer = doc.data()?["role"] == "organizer";
    });
  }

  Future<void> launchWebsite(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/opportunet1.png', height: 55),
      ),
      floatingActionButton: _isOrganizer
          ? FloatingActionButton(
              backgroundColor: Color(0xff84d6fe),
              child: Icon(
                Icons.add,
                color: const Color(0xff17394e),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddVolunteeringScreen()),
                );
              },
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("volunteering")
                    .orderBy("createdAt", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint(snapshot.error.toString());

                    return Center(child: Text(snapshot.error.toString()));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No activities yet."));
                  }

                  final docs = snapshot.data!.docs;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final activity =
                          docs[index].data() as Map<String, dynamic>;
                      final imageUrl = activity["imageUrl"] as String?;
                      final title = activity["title"] as String? ?? "";

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActivityDetailsScreen(activity: activity),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 6,
                                color: Colors.black26,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          activity["imageUrl"],
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 80,
                                          width: 80,
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          child: Icon(Icons.image),
                                        ),
                                ),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    "More Info",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 8),
              Text(
                "If none of these organizations seem appealing, here's a list of some places to consider volunteering:",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Local Libraries: Volunteer to help with organizing books, assisting in reading programs for kids, or running community events.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Food Banks and Soup Kitchens: Assist with meal preparation, distribution, and organizing food drives.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Homeless Shelters: Offer your time to help with daily operations, provide support services, or organize donation drives.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Community Gardens: Help with planting, maintaining, and harvesting gardens that supply fresh produce to local communities",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Animal Shelters: Volunteer to care for animals, assist with adoptions, or help with shelter maintenance.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Local Festivals and Fairs: Assist with organizing, setting up, and running community events.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Graphic Design for Nonprofits: Offer your design skills to create promotional materials for non-profits.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Community Theaters: Help with set design, costumes, or backstage work during performances",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• Start a Community Initiative: Identify a need in your community and create a project to address it, such as a recycling program, community garden, or neighborhood watch group.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
