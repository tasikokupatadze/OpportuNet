import 'package:flutter/material.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color brand = Color(0xff84d6fe);
  static const Color brandDark = Color(0xff2b88b4);
  static const Color background = Color(0xfff5f9fc);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> roadmaps = [
    {
      'grade': '9th Grade',
      'subtitle': 'Explore your interests and build a strong foundation.',
      'private': [
        'Take challenging classes (IB, AP)',
        'Get involved in your community',
        'Take the PSAT 8/9 test',
      ],
      'public': [
        'Engage in school activities',
        'Try to get 50 volunteering hours',
        'Start preparing for SAT',
        'Think of a spike project and major',
      ],
      'summer': [
        'Attend prep classes',
        'Volunteer or join camps',
        'Start researching colleges',
        'Learn a new skill',
        'Think of research or nonprofit ideas',
      ],
    },
    {
      'grade': '10th Grade',
      'subtitle':
          'Develop your academic profile and pursue meaningful activities.',
      'private': [
        'Take challenging classes',
        'Start applying for club/school president role',
        'Continue preparing for PSAT, ACT, SAT tests',
        'Focus on maintaining a 3.5-4.0 GPA',
      ],
      'public': [
        'Start to form clubs that go well with your major',
        'Volunteering hours from 50 to 100',
        'Start to take part in national Olympiads and projects, such as MUN, Young Parliament, and programs your school initiates',
        'Start building your college resume',
        'Keep preparing for tests, take courses and receive certificates',
      ],
      'summer': [
        'Go on college visits',
        'Start thinking about your major and researching your dream/safety schools',
        'Start thinking about your research project',
        'Start building your own nonprofit, website, or project that fits your interests',
      ],
    },
    {
      'grade': '11th Grade',
      'subtitle': 'Strengthen your achievements and prepare for applications.',
      'private': [
        'Take challenging classes',
        'Take the PSAT test',
        'Take the ACT/SAT test',
        'Take the AP tests',
      ],
      'public': [
        'Identify who will write your letters of recommendation',
        'Start thinking about your essay structure and topics',
        'Take part in more Olympiads and try to join national teams in your desired subjects',
        'Start teaching kids for free',
        'Pursue leadership roles in your extracurriculars',
        'Pursue something special that will make you stand out in your application',
        'Start writing a research paper about your desired subject',
        'Consider working with a school counselor',
        'Ask your school counselor about letters of recommendation',
      ],
      'summer': [
        'Get a head start on your college applications',
        'Go on college visits',
        'Get a job, volunteer in summer camps, or find internships',
        'Publish your research project',
        'Finalize your college list',
      ],
    },
    {
      'grade': '12th Grade',
      'subtitle':
          'Complete your applications and make your university decision.',
      'private': [
        'Take challenging classes',
      ],
      'public': [
        'Decide if you will apply Early Decision or Early Action',
        'Stay ahead of your application deadlines',
        'Tell your school where to send your transcripts',
        'Edit and perfect your application essays',
        'Apply for scholarships',
        'Finalize and submit your college applications',
        'Schedule and prepare for college interviews (if applicable)',
        'Finish strong and aim for your best grades',
        'Follow any additional instructions from colleges',
        'Review scholarship offers and financial aid awards',
        'Make your final college decision',
        'Complete the next steps to finalize your acceptance',
        'Accept financial aid awards and make decisions about housing',
      ],
      'summer': [
        'Celebrate your achievements',
        'Enjoy your last summer before university!',
      ],
    },
  ];

  Widget _buildCategory({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe7eef4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: brand..withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: brandDark, size: 21),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff263746),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: brand..withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: brandDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xff455563),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGradePage(Map<String, dynamic> roadmap) {
    return SingleChildScrollView(
      key: PageStorageKey(roadmap['grade']),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [brand, Color(0xffb4e5ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roadmap['grade'],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff17394e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  roadmap['subtitle'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xff244c63),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildCategory(
            title: 'Private Schools',
            icon: Icons.school_outlined,
            items: List<String>.from(roadmap['private']),
          ),
          _buildCategory(
            title: 'Public Schools',
            icon: Icons.account_balance_outlined,
            items: List<String>.from(roadmap['public']),
          ),
          _buildCategory(
            title: 'Summer',
            icon: Icons.wb_sunny_outlined,
            items: List<String>.from(roadmap['summer']),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/opportunet1.png',
          height: 55,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: const Color(0xff17394e),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: '9th'),
                  Tab(text: '10th'),
                  Tab(text: '11th'),
                  Tab(text: '12th'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: roadmaps.map(_buildGradePage).toList(),
      ),
    );
  }
}
