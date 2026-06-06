import 'package:flutter/material.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _yr9key = GlobalKey();
  final GlobalKey _yr10key = GlobalKey();
  final GlobalKey _yr11key = GlobalKey();
  final GlobalKey _yr12key = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  Widget _buildTab(String title, GlobalKey key) {
    return GestureDetector(
      onTap: () => _scrollTo(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff84d6fe),
            fontSize: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, String content, Color color, GlobalKey key) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xff84d6fe).withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xff84d6fe),
              )),
          const SizedBox(height: 10),
          Text(content),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/opportunet1.png',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(height: 20),
                  _buildTab("9th", _yr9key),
                  const SizedBox(height: 20),
                  _buildTab("10th", _yr10key),
                  const SizedBox(height: 20),
                  _buildTab("11th", _yr11key),
                  const SizedBox(height: 20),
                  _buildTab("12th", _yr12key),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSection(
                        "9th",
                        "For private schools:\n"
                            "- Take challenging classes (IB, AP)\n"
                            "- Get involved in your community\n"
                            "- Take the PSAT 8/9 test\n\n"
                            "For public schools:\n"
                            "- Engage in school activities\n"
                            "- Try to get 50 volunteering hours\n"
                            "- Start preparing for SAT\n"
                            "- Think of a spike project and major\n\n"
                            "Summer:\n"
                            "- Attend prep classes\n"
                            "- Volunteer or join camps\n"
                            "- Start researching colleges\n"
                            "- Learn a new skill\n"
                            "- Think of research or nonprofit ideas",
                        const Color(0xff84d6fe),
                        _yr9key),
                    _buildSection(
                        "10th",
                        "Private schools:\n"
                            "-take challenging classes\n"
                            "-start applying for club/school president role\n"
                            "-continue preparing for PSAT, ACT, SAT tests\n"
                            "-focus on maintaining a 3.5-4.0 gpa\n"
                            "Public schools\n"
                            "-start to form clubs that goes well with your major\n"
                            "-volunteering hours from 50 to 100\n"
                            "-start to take part in national Olympiads and projects, such as MUN, young parliament, start applying to projects and programs your school initiates\n"
                            "-start building your college resume\n"
                            "-keep preparing for tests, take courses and receive certificates\n"
                            "Summer\n"
                            "-go on college visits\n"
                            "-start thinking about your major, start researching about your dream/safe schools, and what you need to get in them\n"
                            "-start thinking about your research project\n"
                            "-start building your own nonprofit/website/project of your desire and the one that fits your interest the best\n",
                        const Color(0xff84d6fe),
                        _yr10key),
                    _buildSection(
                        "11th",
                        "Private schools\n"
                            "-take challenging classes\n"
                            "-take the PSAT test\n"
                            "-take the ACT/SAT test\n"
                            "-take the AP tests\n"
                            "Public schools\n"
                            "-identify who will write your letters of recommendations \n"
                            "-start thinking about your essay structure, the spike and the topic it’s going to be about\n"
                            "-take part in more Olympiads, and try to be a part of the national teams of desired subjects\n"
                            "-start teaching kids for free\n"
                            "-persue leadership roles in your extracurriculars\n"
                            "-persue something special, that will make you stand out in your application \n"
                            "-start writing a research paper about the desired subject, better if its an unknown and a niche interest\n"
                            "-hire a school counselor\n"
                            "-ask the school counselor for the letters of recommendations\n"
                            "Summer\n"
                            "-get a head start on your college applications\n"
                            "-go on college visits\n"
                            "-get a job, volunteer in summer camps, find internships\n"
                            "-publish the research project\n"
                            "-finalize your college list\n",
                        const Color(0xff84d6fe),
                        _yr11key),
                    _buildSection(
                        "12th",
                        "-Decide if you’ll apply Early Decision or Early Action\n"
                            "-Take challenging classes\n"
                            "-Stay ahead of your application deadlines\n"
                            "-Tell your school where to send your transcripts\n"
                            "-Edit and perfect your application essays\n"
                            "-Apply for scholarships\n"
                            "-Finalize and submit your college applications.\n"
                            "-Schedule and prepare for college interviews (if applicable)\n"
                            "-Schedule and prepare for college interviews (if applicable)\n"
                            "-Finish strong! Aim to get your best grades yet\n"
                            "-Follow any additional instructions you receive from colleges\n"
                            "-Review scholarship offers and financial aid awards\n"
                            "-Make your final college decision \n"
                            "-Complete next steps to finalize your acceptance\n"
                            "-Accept financial aid awards and make decisions about housing\n",
                        const Color(0xff84d6fe),
                        _yr12key),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
