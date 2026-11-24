import 'package:material_ui/material_ui.dart';

import 'app_ui.dart';

const _notificationAccent = Color(0xff2b88b4);

@immutable
class NotificationItemData {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool isCalendar;
  final bool isUnread;
  final bool opening;

  const NotificationItemData({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isCalendar = false,
    this.isUnread = false,
    this.opening = false,
  });
}

/// Presentation only: callers supply notification data and all actions.
class NotificationInboxView extends StatelessWidget {
  final List<NotificationItemData> items;
  final bool loading;
  final bool signedOut;
  final String? loadError;
  final VoidCallback? onRetry;
  final bool alertsEnabled;
  final bool alertsBusy;
  final String? alertsError;
  final VoidCallback? onToggleAlerts;
  final bool markingAllRead;
  final VoidCallback? onMarkAllRead;
  final ValueChanged<String>? onOpen;

  const NotificationInboxView({
    super.key,
    this.items = const [],
    this.loading = false,
    this.signedOut = false,
    this.loadError,
    this.onRetry,
    this.alertsEnabled = false,
    this.alertsBusy = false,
    this.alertsError,
    this.onToggleAlerts,
    this.markingAllRead = false,
    this.onMarkAllRead,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = items.where((item) => item.isUnread).length;
    final ready = !signedOut && !loading && loadError == null;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 72,
        title: Image.asset(
          'assets/opportunet1.png',
          height: 56,
          fit: BoxFit.contain,
          semanticLabel: 'OpportuNet',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          maxWidth: 800,
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverList.list(children: [
                const NotificationHeader(),
                const SizedBox(height: 18),
                if (!signedOut) ...[
                  NotificationAlertsCard(
                    enabled: alertsEnabled,
                    busy: alertsBusy,
                    error: alertsError,
                    onToggle: onToggleAlerts,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Text(context.l10n.latestUpdates,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          if (ready && unreadCount > 0)
                            _UnreadCount(count: unreadCount),
                        ],
                      ),
                      if (ready && items.isNotEmpty)
                        TextButton(
                          key: const ValueKey('notification-mark-all-read'),
                          onPressed: markingAllRead || unreadCount == 0
                              ? null
                              : onMarkAllRead,
                          style: TextButton.styleFrom(
                              foregroundColor: _readableAccent(context)),
                          child: Text(markingAllRead
                              ? context.l10n.markingRead
                              : context.l10n.markAllRead),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (signedOut)
                  NotificationStateCard(
                    icon: Icons.lock_outline_rounded,
                    title: context.l10n.updatesWaiting,
                    message:
                        context.l10n.signInForUpdates,
                  )
                else if (loadError != null)
                  NotificationStateCard(
                    icon: Icons.cloud_off_outlined,
                    title: context.l10n.updatesLoadFailed,
                    message: loadError!,
                    actionLabel: context.l10n.tryAgain,
                    onAction: onRetry,
                  )
                else if (loading)
                  NotificationStateCard(
                    icon: Icons.notifications_outlined,
                    title: context.l10n.gettingUpdates,
                    message: context.l10n.notificationsAppearHere,
                    busy: true,
                  )
                else if (items.isEmpty)
                  NotificationStateCard(
                    icon: Icons.notifications_none_rounded,
                    title: context.l10n.noNotificationsYet,
                    message:
                        context.l10n.notificationsEmptyBody,
                  ),
              ]),
            ),
            if (ready && items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NotificationUpdateCard(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: onOpen == null ? null : () => onOpen!(item.id),
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: ready && items.isNotEmpty
                    ? Text(
                        context.l10n.showingRecent,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [brandBlue, Color(0xffb6ebff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: brandInk, size: 28),
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.notifications,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: brandInk)),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.notificationsSubtitle,
              style: TextStyle(fontSize: 14, height: 1.5, color: brandInk),
            ),
          ],
        ),
      );
}

class NotificationAlertsCard extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final String? error;
  final VoidCallback? onToggle;

  const NotificationAlertsCard({
    super.key,
    this.enabled = false,
    this.busy = false,
    this.error,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _IconBubble(icon: Icons.phonelink_ring_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.alertsTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface)),
                    const SizedBox(height: 5),
                    Text(
                      enabled ? context.l10n.alertsEnabled : context.l10n.stayUpToDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _readableAccent(context),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(
              enabled
                  ? context.l10n.alertsEnabledBody
                  : context.l10n.alertsOffBody,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('notification-alert-toggle'),
                onPressed: busy ? null : onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: brandInk,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(enabled
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_active_outlined),
                label: Text(
                    busy
                        ? context.l10n.updatingAlerts
                        : enabled
                            ? context.l10n.turnOffAlerts
                            : context.l10n.enableAlerts,
                    textAlign: TextAlign.center),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer, height: 1.4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationUpdateCard extends StatelessWidget {
  final NotificationItemData item;
  final VoidCallback? onTap;
  const NotificationUpdateCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      label: item.isUnread ? context.l10n.unreadNotification : context.l10n.readNotification,
      child: _Panel(
        highlighted: item.isUnread,
        child: InkWell(
          onTap: item.opening ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _IconBubble(
                      icon: item.isCalendar
                          ? Icons.event_outlined
                          : Icons.article_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.isCalendar ? context.l10n.academicCalendar : context.l10n.communityPost,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: _readableAccent(context),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (item.isUnread) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: _readableAccent(context),
                          shape: BoxShape.circle),
                    ),
                  ],
                ]),
                const SizedBox(height: 14),
                Text(item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            item.isUnread ? FontWeight.w700 : FontWeight.w600,
                        height: 1.35,
                        color: colors.onSurface)),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant, height: 1.5)),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  if (item.timeLabel.isNotEmpty) ...[
                    Icon(Icons.schedule_outlined,
                        size: 16, color: colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(item.opening ? context.l10n.opening : item.timeLabel,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 10),
                  if (item.opening)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(Icons.arrow_forward_rounded,
                        size: 18, color: _readableAccent(context)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool busy;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NotificationStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.busy = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => _Panel(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(children: [
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else
              _IconBubble(icon: icon),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('notification-retry'),
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!, textAlign: TextAlign.center),
              ),
            ],
          ]),
        ),
      );
}

class _Panel extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  const _Panel({required this.child, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.12 : 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: highlighted
                ? brandBlue.withValues(alpha: dark ? 0.65 : 0.9)
                : theme.colorScheme.outlineVariant
                    .withValues(alpha: dark ? 0.55 : 0.7),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  const _IconBubble({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: brandBlue.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? brandBlue
                : _notificationAccent,
            size: 24),
      );
}

class _UnreadCount extends StatelessWidget {
  final int count;
  const _UnreadCount({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: brandBlue.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12)),
        child: Text(context.l10n.unreadCount(count),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600, color: _readableAccent(context))),
      );
}

Color _readableAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? brandBlue
        : const Color(0xff17658b);
