import 'app_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatelessWidget {
  final String uid;

  const UserProfile({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Image.asset('assets/opportunet1.png', height: 60),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(context.l10n.profileLoadFailed));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(context.l10n.userNotFound));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final String name = data["name"] ?? "";
          final String surname = data["surname"] ?? "";
          final String age = (data["age"] ?? "").toString();
          final String aboutMe = data["aboutMe"] ?? "";
          final String profileImage = data["profileImage"] ?? "";

          final String fullName = "$name $surname".trim();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff84d6fe), Color(0xffb6ebff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade300,
                          child: ClipOval(
                            child: profileImage.isNotEmpty
                                ? Image.network(
                                    profileImage,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 42,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 42,
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        fullName.isEmpty ? context.l10n.userProfile : fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: brandInk,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.l10n.communityMember,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff2b88b4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        context,
                        icon: Icons.cake_outlined,
                        title: context.l10n.age,
                        value: age.isEmpty ? context.l10n.notAdded : age,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        context,
                        icon: Icons.person_outline,
                        title: context.l10n.name,
                        value: name.isEmpty ? context.l10n.notAdded : name,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _sectionCard(
                  context,
                  title: context.l10n.aboutMe,
                  icon: Icons.edit_note,
                  child: Text(
                    aboutMe.trim().isEmpty
                        ? context.l10n.noAboutSection
                        : aboutMe.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                _sectionCard(
                  context,
                  title: context.l10n.profileDetails,
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: [
                      _detailRow(context, context.l10n.name, name),
                      SizedBox(height: 10),
                      _detailRow(context, context.l10n.surname, surname),
                      SizedBox(height: 10),
                      _detailRow(context, context.l10n.age, age),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Color(0xff84d6fe).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(0xff2b88b4), size: 20),
          ),
          SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Color(0xff84d6fe).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Color(0xff2b88b4), size: 20),
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  static Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? context.l10n.notAdded : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
