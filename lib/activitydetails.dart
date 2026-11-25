import 'app_ui.dart';
import 'opportunity_stats.dart';
import 'saved_opportunities.dart';

import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.opportunet.app';

/// The text sent when a student shares an opportunity: title, its website
/// (when it has one) and a line pointing to the app.
String opportunityShareText(String title, String website, String appLine) =>
    [title.trim(), website.trim(), appLine]
        .where((line) => line.isNotEmpty)
        .join('\n');

class ActivityDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  Future<void> _launchWebsite(String website) async {
    final Uri url = Uri.parse(website);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _share(BuildContext context, String title, String website) async {
    final box = context.findRenderObject() as RenderBox?;
    final text = opportunityShareText(
        title, website, context.l10n.shareFoundOn(kPlayStoreUrl));
    final result = await SharePlus.instance.share(ShareParams(
      text: text,
      subject: title,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
    if (result.status != ShareResultStatus.dismissed) {
      logOpportunityEvent(activity, StatEvent.share);
    }
  }

  @override
  Widget build(BuildContext context) {
    logOpportunityEvent(activity, StatEvent.view);
    final title = activity["title"] ?? "";

    final description = activity["description"] ?? "";
    final website = activity["website"] ?? "";
    final rawAge =
        (activity["ageRequirements"] ?? activity["age"] ?? "").toString();
    final age = rawAge.trim().isEmpty ? context.l10n.notSpecified : rawAge;
    final rawCost = (activity["cost"] ?? "").toString();
    final cost = rawCost.trim().isEmpty ? context.l10n.costNotSpecified : rawCost;
    final imageUrl = activity["imageUrl"] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/opportunet1.png', height: 60),
        centerTitle: true,
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: context.l10n.share,
              icon: Icon(Icons.share_outlined),
              onPressed: () => _share(buttonContext, title, website),
            ),
          ),
          SaveOpportunityButton(data: activity),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          maxWidth: 850,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: 220,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined, size: 56),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.image, size: 80),
                  ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        context.l10n.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(description),
                      SizedBox(height: 24),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.people),
                        title: Text(
                          context.l10n.ageRequirements,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(age),
                      ),
                      ListTile(
                        leading: Icon(Icons.attach_money),
                        title: Text(
                          context.l10n.cost,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(cost),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: website.isEmpty
                              ? null
                              : () => _launchWebsite(website),
                          icon: Icon(Icons.open_in_new),
                          label: Text(
                            context.l10n.visitWebsite,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
