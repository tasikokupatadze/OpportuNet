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
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildTab(String title, GlobalKey key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => _scrollTo(key),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xff84d6fe),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "•  ",
            style: TextStyle(
              color: Color(0xff84d6fe),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String grade,
    required List<String> privateSchool,
    required List<String> publicSchool,
    required List<String> summer,
    required GlobalKey key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black26,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$grade Grade Roadmap",
            style: const TextStyle(
              color: Color(0xff84d6fe),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Private Schools",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...privateSchool.map(_buildBullet),
          const SizedBox(height: 18),
          const Text(
            "Public Schools",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...publicSchool.map(_buildBullet),
          const SizedBox(height: 18),
          const Text(
            "Summer",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...summer.map(_buildBullet),
        ],
      ),
    );
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildTab("9th", _yr9key),
                _buildTab("10th", _yr10key),
                _buildTab("11th", _yr11key),
                _buildTab("12th", _yr12key),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildSection(
                    grade: "9th",
                    key: _yr9key,
                    privateSchool: [
                      "Take challenging classes (IB, AP)",
                      "Get involved in your community",
                      "Take the PSAT 8/9 test",
                    ],
                    publicSchool: [
                      "Engage in school activities",
                      "Try to get 50 volunteering hours",
                      "Start preparing for SAT",
                      "Think of a spike project and major",
                    ],
                    summer: [
                      "Attend prep classes",
                      "Volunteer or join camps",
                      "Start researching colleges",
                      "Learn a new skill",
                      "Think of research or nonprofit ideas",
                    ],
                  ),
                  _buildSection(
                    grade: "10th",
                    key: _yr10key,
                    privateSchool: [
                      "Take challenging classes",
                      "Start applying for club/school president role",
                      "Continue preparing for PSAT, ACT, SAT tests",
                      "Focus on maintaining a 3.5-4.0 GPA",
                    ],
                    publicSchool: [
                      "Start to form clubs that goes well with your major",
                      "Volunteering hours from 50 to 100",
                      "Start to take part in national Olympiads and projects, such as MUN, Young Parliament, start applying to projects and programs your school initiates",
                      "Start building your college resume",
                      "Keep preparing for tests, take courses and receive certificates",
                    ],
                    summer: [
                      "Go on college visits",
                      "Start thinking about your major, start researching about your dream/safe schools, and what you need to get in them",
                      "Start thinking about your research project",
                      "Start building your own nonprofit/website/project of your desire and the one that fits your interest the best",
                    ],
                  ),
                  _buildSection(
                    grade: "11th",
                    key: _yr11key,
                    privateSchool: [
                      "Take challenging classes",
                      "Take the PSAT test",
                      "Take the ACT/SAT test",
                      "Take the AP tests",
                    ],
                    publicSchool: [
                      "Identify who will write your letters of recommendations",
                      "Start thinking about your essay structure, the spike and the topic it’s going to be about",
                      "Take part in more Olympiads, and try to be a part of the national teams of desired subjects",
                      "Start teaching kids for free",
                      "Pursue leadership roles in your extracurriculars",
                      "Pursue something special, that will make you stand out in your application",
                      "Start writing a research paper about the desired subject, better if it’s an unknown and a niche interest",
                      "Hire a school counselor",
                      "Ask the school counselor for the letters of recommendations",
                    ],
                    summer: [
                      "Get a head start on your college applications",
                      "Go on college visits",
                      "Get a job, volunteer in summer camps, find internships",
                      "Publish the research project",
                      "Finalize your college list",
                    ],
                  ),
                  _buildSection(
                    grade: "12th",
                    key: _yr12key,
                    privateSchool: [
                      "Take challenging classes",
                    ],
                    publicSchool: [
                      "Decide if you’ll apply Early Decision or Early Action",
                      "Stay ahead of your application deadlines",
                      "Tell your school where to send your transcripts",
                      "Edit and perfect your application essays",
                      "Apply for scholarships",
                      "Finalize and submit your college applications",
                      "Schedule and prepare for college interviews (if applicable)",
                      "Finish strong! Aim to get your best grades yet",
                      "Follow any additional instructions you receive from colleges",
                      "Review scholarship offers and financial aid awards",
                      "Make your final college decision",
                      "Complete next steps to finalize your acceptance",
                      "Accept financial aid awards and make decisions about housing",
                    ],
                    summer: [
                      "Celebrate your achievements",
                      "Enjoy your last summer before university!"
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
