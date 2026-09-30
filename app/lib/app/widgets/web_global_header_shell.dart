import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/notifications/models/app_update_notification.dart';
import '../services/web_sync_status_controller.dart';
import '../services/web_update_notification_controller.dart';
import '../../profile/screens/web_profile_settings_page.dart';

/// Header global Web inspirado no mesmo shell visual do app desktop.
///
/// Importante:
/// Este widget fica no `MaterialApp.builder`, acima do Navigator principal.
/// Por isso ele NÃO usa Tooltip/showModalBottomSheet diretamente no header,
/// evitando a exceção "No Overlay widget found".
class WebGlobalHeaderShell extends StatefulWidget {
  const WebGlobalHeaderShell({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<WebGlobalHeaderShell> createState() => _WebGlobalHeaderShellState();
}

class _WebGlobalHeaderShellState extends State<WebGlobalHeaderShell> {
  static const Color _background = Color(0xFFF7FBF1);
  static const Color _border = Color(0xFFC7DFC9);
  final ProfileRepository _profileRepository = ProfileRepository();

  late final WebSyncStatusController _syncStatus;
  late final WebUpdateNotificationController _notifications;

  StreamSubscription<AuthState>? _authSubscription;

  bool _authenticated = false;
  bool _isSigningOut = false;
  bool _profileOpen = false;
  bool _notificationsOpen = false;
  String _displayName = 'Usuário';
  String? _cachedEmail;

  @override
  void initState() {
    super.initState();

    _syncStatus = WebSyncStatusController();
    _notifications = WebUpdateNotificationController(syncStatus: _syncStatus);

    _syncStatus.initialize();
    _notifications.initialize();

    final auth = Supabase.instance.client.auth;

    _authenticated = auth.currentSession != null;
    _cachedEmail = auth.currentUser?.email;

    _authSubscription = auth.onAuthStateChange.listen(_handleAuthStateChange);

    if (_authenticated) {
      unawaited(_loadProfile());
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notifications.dispose();
    _syncStatus.dispose();
    super.dispose();
  }

  void _handleAuthStateChange(AuthState state) {
    final session = state.session;
    final authenticated = session != null;

    if (!mounted) {
      return;
    }

    setState(() {
      _authenticated = authenticated;

      if (authenticated) {
        _cachedEmail = session.user.email;
      } else {
        _profileOpen = false;
        _notificationsOpen = false;
        _displayName = 'Usuário';
        _cachedEmail = null;
      }
    });

    if (authenticated) {
      unawaited(_loadProfile());
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();
      final user = Supabase.instance.client.auth.currentUser;

      if (!mounted) return;

      setState(() {
        final cleanName = profile?.fullName.trim() ?? '';
        _displayName = cleanName.isEmpty ? 'Usuário' : cleanName;
        _cachedEmail = user?.email;
      });
    } catch (_) {
      final user = Supabase.instance.client.auth.currentUser;

      if (!mounted) return;

      setState(() {
        _cachedEmail = user?.email;
      });
    }
  }

  void _toggleProfile() {
    setState(() {
      _profileOpen = !_profileOpen;
      _notificationsOpen = false;
    });
  }

  void _closeFloatingPanels() {
    if (!_profileOpen && !_notificationsOpen) return;
    setState(() {
      _profileOpen = false;
      _notificationsOpen = false;
    });
  }

  Future<void> _toggleNotifications() async {
    final next = !_notificationsOpen;

    setState(() {
      _notificationsOpen = next;
      _profileOpen = false;
    });

    if (next) {
      await _notifications.markAsRead();

      if (_notifications.notification == null && !_notifications.refreshing) {
        await _notifications.refresh();
      }
    }
  }

  Future<void> _openProfileSettings(WebProfileSettingsSection section) async {
    _closeFloatingPanels();

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WebProfileSettingsPage(initialSection: section),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
      _profileOpen = false;
      _notificationsOpen = false;
    });

    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: _background,
                border: Border(bottom: BorderSide(color: _border, width: 1)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: _authenticated
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WebNotificationBell(
                            controller: _notifications,
                            onTap: _toggleNotifications,
                          ),
                          const SizedBox(width: 8),
                          WebSyncStatusIndicator(controller: _syncStatus),
                          const SizedBox(width: 8),
                          _HeaderIcon(
                            semanticsLabel: 'Meu perfil',
                            icon: Icons.person_outline_rounded,
                            filled: true,
                            selected: _profileOpen,
                            onTap: _toggleProfile,
                          ),
                          const SizedBox(width: 6),
                          _HeaderIcon(
                            semanticsLabel: _isSigningOut
                                ? 'Saindo da conta'
                                : 'Sair da conta',
                            icon: Icons.logout_rounded,
                            loading: _isSigningOut,
                            onTap: _isSigningOut ? null : _signOut,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                widget.child,

                if (_profileOpen || _notificationsOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeFloatingPanels,
                      child: Container(
                        color: Colors.black.withValues(alpha: .28),
                      ),
                    ),
                  ),

                if (_notificationsOpen)
                  Positioned(
                    top: 12,
                    right: 18,
                    child: _WebNotificationPanel(
                      controller: _notifications,
                      onClose: _closeFloatingPanels,
                    ),
                  ),

                if (_profileOpen)
                  Positioned(
                    top: 12,
                    right: 18,
                    child: _ProfilePanel(
                      displayName: _displayName,
                      email:
                          Supabase.instance.client.auth.currentUser?.email ??
                          _cachedEmail ??
                          'E-mail não disponível',
                      onClose: _closeFloatingPanels,
                      onPreferences: () => _openProfileSettings(
                        WebProfileSettingsSection.preferences,
                      ),
                      onSecurity: () => _openProfileSettings(
                        WebProfileSettingsSection.security,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebNotificationBell extends StatelessWidget {
  const _WebNotificationBell({required this.controller, required this.onTap});

  final WebUpdateNotificationController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final unread = controller.hasUnread;

        return Semantics(
          button: true,
          label: unread ? 'Nova atualização disponível' : 'Notificações',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: 28,
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      unread
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_rounded,
                      color: unread
                          ? const Color(0xFF198754)
                          : const Color(0xFF68746B),
                      size: 20,
                    ),
                  ),
                  if (unread)
                    const Positioned(
                      right: 1,
                      top: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF198754),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 7, height: 7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WebSyncStatusIndicator extends StatefulWidget {
  const WebSyncStatusIndicator({super.key, required this.controller});

  final WebSyncStatusController controller;

  @override
  State<WebSyncStatusIndicator> createState() => _WebSyncStatusIndicatorState();
}

class _WebSyncStatusIndicatorState extends State<WebSyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_changed);
    _syncAnimation();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _rotationController.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    _syncAnimation();
    setState(() {});
  }

  void _syncAnimation() {
    final animate =
        widget.controller.state == WebSyncVisualState.syncing ||
        widget.controller.state == WebSyncVisualState.checking;

    if (animate) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
      _rotationController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = _resolveVisual();

    return Semantics(
      label: visual.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: visual.background,
          shape: BoxShape.circle,
          border: Border.all(color: visual.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: visual.foreground.withValues(alpha: .07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: visual.animate
                ? AnimatedBuilder(
                    key: ValueKey<String>(visual.key),
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Icon(
                      visual.icon,
                      size: 17,
                      color: visual.foreground,
                    ),
                  )
                : Icon(
                    key: ValueKey<String>(visual.key),
                    visual.icon,
                    size: 17,
                    color: visual.foreground,
                  ),
          ),
        ),
      ),
    );
  }

  _WebSyncVisual _resolveVisual() {
    switch (widget.controller.state) {
      case WebSyncVisualState.checking:
        return const _WebSyncVisual(
          key: 'checking',
          icon: Icons.cloud_sync_rounded,
          label: 'Verificando conexão e sincronização',
          foreground: Color(0xFF68746B),
          background: Color(0xFFF3F8EE),
          border: Color(0xFFC7DFC9),
          animate: true,
        );
      case WebSyncVisualState.syncing:
        return const _WebSyncVisual(
          key: 'syncing',
          icon: Icons.sync_rounded,
          label: 'Sincronizando',
          foreground: Color(0xFF9A6700),
          background: Color(0xFFFFF4CC),
          border: Color(0xFF9A6700),
          animate: true,
        );
      case WebSyncVisualState.error:
        return const _WebSyncVisual(
          key: 'error',
          icon: Icons.sync_problem_rounded,
          label: 'Erro de sincronização',
          foreground: Color(0xFFB3261E),
          background: Color(0xFFFFE9E7),
          border: Color(0xFFB3261E),
        );
      case WebSyncVisualState.online:
        return const _WebSyncVisual(
          key: 'online',
          icon: Icons.cloud_done_rounded,
          label: 'Online',
          foreground: Color(0xFF3B6939),
          background: Color(0xFFBCF0B4),
          border: Color(0xFF3B6939),
        );
    }
  }
}

class _WebSyncVisual {
  const _WebSyncVisual({
    required this.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    this.animate = false,
  });

  final String key;
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final bool animate;
}

class _WebNotificationPanel extends StatelessWidget {
  const _WebNotificationPanel({
    required this.controller,
    required this.onClose,
  });

  final WebUpdateNotificationController controller;
  final VoidCallback onClose;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} • '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width < 460 ? width - 36 : 390),
      child: Material(
        elevation: 10,
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 390,
          constraints: const BoxConstraints(maxHeight: 480),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC7DFC9)),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final notification = controller.notification;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Notificações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: controller.refreshing
                              ? null
                              : () => controller.refresh(),
                          icon: controller.refreshing
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFC7DFC9)),
                  if (controller.error != null)
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        controller.error!,
                        style: const TextStyle(color: Color(0xFFB3261E)),
                      ),
                    )
                  else if (notification == null)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 34,
                            color: Color(0xFF68746B),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Nenhuma notificação disponível.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF68746B)),
                          ),
                        ],
                      ),
                    )
                  else
                    _NotificationCard(
                      notification: notification,
                      date: _formatDate(notification.publishedAt),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.date});

  final AppUpdateNotification notification;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC7DFC9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.system_update_alt_rounded,
                  color: Color(0xFF198754),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'v${notification.version}',
                    style: const TextStyle(
                      color: Color(0xFF198754),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(notification.message),
            const SizedBox(height: 12),
            Text(
              date,
              style: const TextStyle(color: Color(0xFF68746B), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.semanticsLabel,
    required this.icon,
    this.onTap,
    this.filled = false,
    this.selected = false,
    this.loading = false,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool selected;
  final bool loading;

  static const Color _primary = Color(0xFF3B6939);
  static const Color _primarySoft = Color(0xFFBCF0B4);
  static const Color _muted = Color(0xFF68746B);

  @override
  Widget build(BuildContext context) {
    final useFilled = filled || selected;

    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: useFilled ? _primarySoft : Colors.transparent,
              shape: BoxShape.circle,
              border: useFilled
                  ? Border.all(color: _primary.withValues(alpha: .30))
                  : null,
            ),
            child: loading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: _primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 19,
                    color: filled || selected ? _primary : _muted,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.displayName,
    required this.email,
    required this.onClose,
    required this.onPreferences,
    required this.onSecurity,
  });

  final String displayName;
  final String email;
  final VoidCallback onClose;
  final VoidCallback onPreferences;
  final VoidCallback onSecurity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth < 600 ? maxWidth - 36 : 520,
      ),
      child: Material(
        elevation: 10,
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 520,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.primary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meu perfil',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Informações da sua conta.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: .20),
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProfileActionTile(
                icon: Icons.tune_rounded,
                title: 'Preferências',
                subtitle: 'Ajuste comportamento e experiência do app.',
                onTap: onPreferences,
              ),
              const SizedBox(height: 10),
              _ProfileActionTile(
                icon: Icons.shield_outlined,
                title: 'Segurança',
                subtitle: 'Gerencie senha e dados de acesso.',
                onTap: onSecurity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
