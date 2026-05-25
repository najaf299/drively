import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Drivly toast / snackbar system — Build Spec v3 §4.
///
/// A unified, theme-aware toast built on a host inserted at the app root
/// ([DrivlyToastHost], mounted via `MaterialApp.builder`). Call from anywhere
/// without a `BuildContext`:
///
/// ```dart
/// DrivlyToast.success('Booking confirmed', message: 'Trip starts in 25 min');
/// DrivlyToast.error('Payment failed', action: ToastAction('RETRY', onTap: retry));
/// final id = DrivlyToast.loading('Uploading…');  DrivlyToast.dismiss(id);
/// ```
///
/// Colours re-resolve from the active [Brightness], so it looks right in both
/// the dark and (upcoming) light theme. Only one toast shows at a time; a new
/// one replaces the current.
enum ToastVariant { success, error, warning, info, loading, promo }

enum ToastDismissReason { timeout, swipe, action, programmatic }

/// A tappable action shown on the right of a toast (e.g. UNDO / RETRY).
class ToastAction {
  final String label;
  final VoidCallback onTap;
  const ToastAction(this.label, {required this.onTap});
}

/// Immutable description of one toast.
class _ToastSpec {
  final String id;
  final ToastVariant variant;
  final String title;
  final String? message;
  final ToastAction? action;
  final IconData? icon; // overrides the variant default
  final Duration? duration; // null → persistent
  final WidgetBuilder? builder; // custom payload
  final void Function(ToastDismissReason reason)? onDismiss;

  const _ToastSpec({
    required this.id,
    required this.variant,
    required this.title,
    this.message,
    this.action,
    this.icon,
    this.duration,
    this.builder,
    this.onDismiss,
  });
}

class DrivlyToast {
  DrivlyToast._();

  static _DrivlyToastHostState? _host;
  static int _seq = 0;
  static String _genId() =>
      'toast_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  /// Default auto-dismiss per variant (loading & promo are persistent).
  static Duration? _defaultDuration(ToastVariant v) => switch (v) {
        ToastVariant.success => const Duration(seconds: 3),
        ToastVariant.info => const Duration(seconds: 4),
        ToastVariant.warning => const Duration(seconds: 5),
        ToastVariant.error => const Duration(seconds: 6),
        ToastVariant.loading => null,
        ToastVariant.promo => null,
      };

  static String _show(_ToastSpec spec) {
    _host?.show(spec);
    return spec.id;
  }

  static String success(String title,
          {String? message, ToastAction? action, IconData? icon, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.success,
        title: title,
        message: message,
        action: action,
        icon: icon,
        duration: _defaultDuration(ToastVariant.success),
      ));

  static String error(String title,
          {String? message, ToastAction? action, IconData? icon, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.error,
        title: title,
        message: message,
        action: action,
        icon: icon,
        duration: _defaultDuration(ToastVariant.error),
      ));

  static String warning(String title,
          {String? message, ToastAction? action, IconData? icon, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.warning,
        title: title,
        message: message,
        action: action,
        icon: icon,
        duration: _defaultDuration(ToastVariant.warning),
      ));

  static String info(String title,
          {String? message, ToastAction? action, IconData? icon, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.info,
        title: title,
        message: message,
        action: action,
        icon: icon,
        duration: _defaultDuration(ToastVariant.info),
      ));

  /// Persistent loading toast (spinner). Dismiss it explicitly with [dismiss].
  static String loading(String title, {String? message, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.loading,
        title: title,
        message: message,
        duration: null,
      ));

  static String promo(String title,
          {String? message, ToastAction? action, IconData? icon, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.promo,
        title: title,
        message: message,
        action: action,
        icon: icon,
        duration: const Duration(seconds: 6),
      ));

  /// A fully custom toast body.
  static String custom(
          {required WidgetBuilder builder, Duration? duration, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.info,
        title: '',
        builder: builder,
        duration: duration,
      ));

  /// Loading → success/error around a future (Build Spec §4.5 promise pattern).
  static Future<T> promise<T>(
    Future<T> future, {
    required String loading,
    required String Function(T value) success,
    required String Function(Object error) error,
  }) async {
    final id = DrivlyToast.loading(loading);
    try {
      final value = await future;
      dismiss(id);
      DrivlyToast.success(success(value));
      return value;
    } catch (e) {
      dismiss(id);
      DrivlyToast.error(error(e));
      rethrow;
    }
  }

  /// Gmail-style undo: shows a toast, commits the destructive op only if the
  /// window elapses without the user tapping UNDO.
  static String undoable({
    required String message,
    required VoidCallback onUndo,
    required VoidCallback onCommit,
    Duration window = const Duration(seconds: 5),
  }) {
    final id = _genId();
    var undone = false;
    return _show(_ToastSpec(
      id: id,
      variant: ToastVariant.success,
      title: message,
      duration: window,
      action: ToastAction('UNDO', onTap: () {
        undone = true;
        onUndo();
        dismiss(id);
      }),
      onDismiss: (_) {
        if (!undone) onCommit();
      },
    ));
  }

  static void dismiss([String? id]) =>
      _host?.dismiss(id, ToastDismissReason.programmatic);
}

/// Mounts the toast overlay above the whole app. Wire via:
/// `MaterialApp.builder: (context, child) => DrivlyToastHost(child: child!)`.
class DrivlyToastHost extends StatefulWidget {
  final Widget child;
  const DrivlyToastHost({super.key, required this.child});

  @override
  State<DrivlyToastHost> createState() => _DrivlyToastHostState();
}

class _DrivlyToastHostState extends State<DrivlyToastHost> {
  _ToastSpec? _current;

  @override
  void initState() {
    super.initState();
    DrivlyToast._host = this;
  }

  @override
  void dispose() {
    if (DrivlyToast._host == this) DrivlyToast._host = null;
    super.dispose();
  }

  void show(_ToastSpec spec) {
    // Single-toast policy: a new toast replaces the current one.
    setState(() => _current = spec);
  }

  void dismiss(String? id, ToastDismissReason reason) {
    final cur = _current;
    if (cur == null) return;
    if (id != null && cur.id != id) return;
    cur.onDismiss?.call(reason);
    if (mounted) setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current;
    return Stack(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      children: [
        widget.child,
        if (cur != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: _ToastCard(
                key: ValueKey(cur.id),
                spec: cur,
                onClose: (reason) => dismiss(cur.id, reason),
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastStyle {
  final Color accent;
  final Color tileBg;
  final IconData icon;
  const _ToastStyle(this.accent, this.tileBg, this.icon);
}

_ToastStyle _styleFor(ToastVariant v, Brightness b) {
  final light = b == Brightness.light;
  switch (v) {
    case ToastVariant.success:
      return _ToastStyle(
          const Color(0xFF16A34A),
          light ? const Color(0xFFE6F7EC) : const Color(0xFF0F2A1A),
          Icons.check_circle_outline);
    case ToastVariant.error:
      return _ToastStyle(
          const Color(0xFFDC2626),
          light ? const Color(0xFFFDECEC) : const Color(0xFF2A0F11),
          Icons.error_outline);
    case ToastVariant.warning:
      return _ToastStyle(
          const Color(0xFFD97706),
          light ? const Color(0xFFFFF4E0) : const Color(0xFF2A1F0A),
          Icons.warning_amber_rounded);
    case ToastVariant.info:
      return _ToastStyle(
          const Color(0xFF2563EB),
          light ? const Color(0xFFE7EEFE) : const Color(0xFF132036),
          Icons.info_outline);
    case ToastVariant.loading:
      return _ToastStyle(
          const Color(0xFFCBF24A),
          light ? const Color(0xFFF1F3F7) : const Color(0xFF1B1F2A),
          Icons.autorenew);
    case ToastVariant.promo:
      return _ToastStyle(
          const Color(0xFF8A6BFF),
          light ? const Color(0xFFF1FAD0) : const Color(0xFF1E1A2E),
          Icons.auto_awesome);
  }
}

class _ToastCard extends StatefulWidget {
  final _ToastSpec spec;
  final void Function(ToastDismissReason reason) onClose;
  const _ToastCard({super.key, required this.spec, required this.onClose});

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _enter;
  AnimationController? _progress;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();

    _haptic();

    final d = widget.spec.duration;
    if (d != null) {
      _progress = AnimationController(vsync: this, duration: d)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            widget.onClose(ToastDismissReason.timeout);
          }
        })
        ..forward();
    }
  }

  void _haptic() {
    switch (widget.spec.variant) {
      case ToastVariant.success:
        HapticFeedback.lightImpact();
      case ToastVariant.error:
        HapticFeedback.heavyImpact();
      case ToastVariant.warning:
        HapticFeedback.mediumImpact();
      case ToastVariant.info:
      case ToastVariant.promo:
        HapticFeedback.selectionClick();
      case ToastVariant.loading:
        break;
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _progress?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final style = _styleFor(spec.variant, brightness);

    final surface = dark ? const Color(0xFF14171F) : Colors.white;
    final fg = dark ? const Color(0xFFF4F5F7) : const Color(0xFF0B0D14);
    final mutedFg = dark ? const Color(0xFF8A8F9C) : const Color(0xFF5A6172);

    final enter = CurvedAnimation(
      parent: _enter,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );

    final card = Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Color.alphaBlend(
                Colors.black.withValues(alpha: dark ? 0.45 : 0.12),
                Colors.transparent),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: spec.builder != null
          ? spec.builder!(context)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconTile(
                        style: style,
                        variant: spec.variant,
                        icon: spec.icon ?? style.icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              spec.title,
                              style: TextStyle(
                                color: fg,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            if (spec.message != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                spec.message!,
                                style: TextStyle(
                                  color: mutedFg,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (spec.action != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: () {
                              spec.action!.onTap();
                              widget.onClose(ToastDismissReason.action);
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              spec.action!.label.toUpperCase(),
                              style: TextStyle(
                                color: style.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        )
                      else
                        _CloseButton(
                          color: mutedFg,
                          onTap: () =>
                              widget.onClose(ToastDismissReason.programmatic),
                        ),
                    ],
                  ),
                ),
                // Countdown progress bar.
                if (_progress != null)
                  AnimatedBuilder(
                    animation: _progress!,
                    builder: (_, __) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 1 - _progress!.value,
                        child: Container(height: 3, color: style.accent),
                      ),
                    ),
                  ),
              ],
            ),
    );

    // Swipe-to-dismiss (horizontal) + pause-on-press for the countdown.
    final dismissible = Dismissible(
      key: ValueKey('${spec.id}_d'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => widget.onClose(ToastDismissReason.swipe),
      child: Listener(
        onPointerDown: (_) => _progress?.stop(),
        onPointerUp: (_) => _progress?.forward(),
        child: card,
      ),
    );

    return Semantics(
      liveRegion: true,
      label: '${spec.variant.name} ${spec.title}. ${spec.message ?? ''}',
      child: AnimatedBuilder(
        animation: enter,
        builder: (_, child) => Opacity(
          opacity: enter.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - enter.value)),
            child: Transform.scale(
              scale: 0.96 + 0.04 * enter.value,
              child: child,
            ),
          ),
        ),
        child: Material(color: Colors.transparent, child: dismissible),
      ),
    );
  }
}

class _IconTile extends StatefulWidget {
  final _ToastStyle style;
  final ToastVariant variant;
  final IconData icon;
  const _IconTile(
      {required this.style, required this.variant, required this.icon});

  @override
  State<_IconTile> createState() => _IconTileState();
}

class _IconTileState extends State<_IconTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void initState() {
    super.initState();
    if (widget.variant == ToastVariant.loading) {
      _spin = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, color: widget.style.accent, size: 22);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.style.tileBg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child:
          _spin != null ? RotationTransition(turns: _spin!, child: icon) : icon,
    );
  }
}

class _CloseButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _CloseButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.close, size: 16, color: color),
      ),
    );
  }
}
