import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Drivly toast / snackbar system — **iOS Pill · Spec v4** (supersedes v1–v3).
///
/// A single notification surface for the whole app: one capsule shape, one
/// motion language, four semantic colours. Top-centred, neutral body, the
/// status dot carries the meaning. Call from anywhere without a `BuildContext`:
///
/// ```dart
/// DrivlyToast.success('Ride booked', message: 'Driver arriving in 3 min');
/// DrivlyToast.error('Payment failed', action: ToastAction('RETRY', onTap: retry));
/// final id = DrivlyToast.loading('Uploading…');  DrivlyToast.dismiss(id);
/// ```
///
/// Theme-aware: surface, border, shadow and text re-resolve from the active
/// [Brightness] (the pill body stays neutral in both). Only one pill shows at a
/// time — a new one replaces the current.
enum ToastVariant { success, error, warning, info, loading, promo }

enum ToastDismissReason { timeout, swipe, action, programmatic }

/// A tappable action shown on the right of a pill (e.g. UNDO / RETRY).
class ToastAction {
  final String label;
  final VoidCallback onTap;
  const ToastAction(this.label, {required this.onTap});
}

/// Immutable description of one pill.
class _ToastSpec {
  final String id;
  final ToastVariant variant;
  final String title;
  final String? message;
  final ToastAction? action;
  final IconData? icon; // accepted for back-compat; pills use a dot, not an icon
  final Duration? duration; // null → persistent
  final VoidCallback? onTap; // routes on tap (Spec v4 §05 interaction)
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
    this.onTap,
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

  /// Default auto-dismiss per variant. Spec hold is 3 200 ms; errors get a
  /// little longer to read, loading & promo persist.
  static Duration? _defaultDuration(ToastVariant v) => switch (v) {
        ToastVariant.success => const Duration(milliseconds: 3200),
        ToastVariant.info => const Duration(milliseconds: 3200),
        ToastVariant.warning => const Duration(milliseconds: 4000),
        ToastVariant.error => const Duration(milliseconds: 5000),
        ToastVariant.loading => null,
        ToastVariant.promo => const Duration(milliseconds: 6000),
      };

  static String _show(_ToastSpec spec) {
    _host?.show(spec);
    return spec.id;
  }

  static String success(String title,
          {String? message,
          ToastAction? action,
          IconData? icon,
          VoidCallback? onTap,
          String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.success,
        title: title,
        message: message,
        action: action,
        icon: icon,
        onTap: onTap,
        duration: _defaultDuration(ToastVariant.success),
      ));

  static String error(String title,
          {String? message,
          ToastAction? action,
          IconData? icon,
          VoidCallback? onTap,
          String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.error,
        title: title,
        message: message,
        action: action,
        icon: icon,
        onTap: onTap,
        duration: _defaultDuration(ToastVariant.error),
      ));

  static String warning(String title,
          {String? message,
          ToastAction? action,
          IconData? icon,
          VoidCallback? onTap,
          String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.warning,
        title: title,
        message: message,
        action: action,
        icon: icon,
        onTap: onTap,
        duration: _defaultDuration(ToastVariant.warning),
      ));

  static String info(String title,
          {String? message,
          ToastAction? action,
          IconData? icon,
          VoidCallback? onTap,
          String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.info,
        title: title,
        message: message,
        action: action,
        icon: icon,
        onTap: onTap,
        duration: _defaultDuration(ToastVariant.info),
      ));

  /// Persistent loading pill (small spinner where the dot sits). Dismiss it
  /// explicitly with [dismiss].
  static String loading(String title, {String? message, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.loading,
        title: title,
        message: message,
        duration: null,
      ));

  static String promo(String title,
          {String? message,
          ToastAction? action,
          IconData? icon,
          VoidCallback? onTap,
          String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.promo,
        title: title,
        message: message,
        action: action,
        icon: icon,
        onTap: onTap,
        duration: _defaultDuration(ToastVariant.promo),
      ));

  /// A fully custom pill body.
  static String custom(
          {required WidgetBuilder builder, Duration? duration, String? id}) =>
      _show(_ToastSpec(
        id: id ?? _genId(),
        variant: ToastVariant.info,
        title: '',
        builder: builder,
        duration: duration,
      ));

  /// Loading → success/error around a future (promise pattern).
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

  /// Gmail-style undo: shows a pill, commits the destructive op only if the
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

/// Mounts the pill overlay above the whole app. Wire via:
/// `MaterialApp.builder: (context, child) => DrivlyToastHost(child: child!)`.
class DrivlyToastHost extends StatefulWidget {
  final Widget child;
  const DrivlyToastHost({super.key, required this.child});

  @override
  State<DrivlyToastHost> createState() => _DrivlyToastHostState();
}

class _DrivlyToastHostState extends State<DrivlyToastHost> {
  _ToastSpec? _current;
  _ToastCardState? _activeCard;

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
    // Single-pill policy: a new pill replaces the current one (Spec v4 §05).
    setState(() => _current = spec);
  }

  /// Programmatic dismiss — asks the live card to play its exit animation.
  void dismiss(String? id, ToastDismissReason reason) {
    final cur = _current;
    if (cur == null) return;
    if (id != null && cur.id != id) return;
    final card = _activeCard;
    if (card != null) {
      card.requestExit(reason);
    } else {
      _finish(cur, reason);
    }
  }

  void _finish(_ToastSpec spec, ToastDismissReason reason) {
    spec.onDismiss?.call(reason);
    if (mounted && _current?.id == spec.id) {
      setState(() => _current = null);
    }
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
            top: 0,
            left: 0,
            right: 0,
            // Top-centred, 12pt below the safe area (Spec v4 §01/§02).
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.topCenter,
                child: _ToastCard(
                  key: ValueKey(cur.id),
                  spec: cur,
                  onReady: (s) => _activeCard = s,
                  onGone: (s) {
                    if (_activeCard == s) _activeCard = null;
                  },
                  onClosed: (reason) => _finish(cur, reason),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Tokens ──────────────────────────────────────────────────────────────────

/// Surface tokens (Spec v4 §04). The body stays neutral in both themes.
class _PillTokens {
  final Color bg;
  final Color border;
  final Color text;
  final Color subtext;
  final Color shadow;
  final Color highlight; // inner top sheen (dark only)
  final double glowAlpha; // halo behind the dot

  const _PillTokens({
    required this.bg,
    required this.border,
    required this.text,
    required this.subtext,
    required this.shadow,
    required this.highlight,
    required this.glowAlpha,
  });

  static _PillTokens of(Brightness b) => b == Brightness.dark
      ? const _PillTokens(
          bg: Color(0xFF1B1E28),
          border: Color(0x662E3242), // #2E3242 @ 40%
          text: Color(0xFFFFFFFF),
          subtext: Color(0xFF7B7F96),
          shadow: Color(0x8C000000), // black @ 0.55
          highlight: Color(0x0AFFFFFF), // white @ ~4%
          glowAlpha: 0.25,
        )
      : const _PillTokens(
          bg: Color(0xFFFFFFFF),
          border: Color(0xFFE4E6EF),
          text: Color(0xFF13151C),
          subtext: Color(0xFF5B6072),
          shadow: Color(0x2E000000), // black @ 0.18
          highlight: Color(0x00000000), // none
          glowAlpha: 0.30,
        );
}

/// Semantic dot colour (Spec v4 §04). Theme-independent.
Color _dotColor(ToastVariant v) => switch (v) {
      ToastVariant.success => const Color(0xFF22C55E),
      ToastVariant.info => const Color(0xFF5B6EF5),
      ToastVariant.warning => const Color(0xFFF97316),
      ToastVariant.error => const Color(0xFFEF4444),
      ToastVariant.loading => const Color(0xFF5B6EF5),
      ToastVariant.promo => const Color(0xFF7C5CFF), // brand accent
    };

// ── Card ──────────────────────────────────────────────────────────────────

class _ToastCard extends StatefulWidget {
  final _ToastSpec spec;
  final void Function(_ToastCardState) onReady;
  final void Function(_ToastCardState) onGone;
  final void Function(ToastDismissReason reason) onClosed;
  const _ToastCard({
    super.key,
    required this.spec,
    required this.onReady,
    required this.onGone,
    required this.onClosed,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _enter; // spring-up (Spec v4 §03)
  late final AnimationController _exit; // soft fade
  late final AnimationController _pulse; // status-dot "live" pulse
  AnimationController? _spin; // loading spinner
  AnimationController? _hold; // auto-dismiss timer (no visual)

  late final Animation<double> _opacityIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _yIn;
  late final Animation<double> _exitCurve;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    widget.onReady(this);

    // Entry: spring up — scale 0.4→1 with a subtle overshoot to 1.04, opacity
    // 0→1, y −20→0, settling in ~420 ms.
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacityIn = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _yIn = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
    );
    _scaleIn = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 28,
      ),
    ]).animate(_enter);

    // Exit: soft fade — scale 1→0.6, opacity 1→0, y 0→−10 over 220 ms, iOS ease.
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _exitCurve = CurvedAnimation(
      parent: _exit,
      curve: const Cubic(0.32, 0.72, 0, 1),
    );

    // Status-dot pulse — independent 1.6 s loop.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    if (widget.spec.variant == ToastVariant.loading) {
      _spin = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat();
    }

    _enter.forward();
    _haptic();

    // Auto-dismiss as a pausable timer (no countdown bar in the pill).
    final d = widget.spec.duration;
    if (d != null) {
      _hold = AnimationController(vsync: this, duration: d)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            requestExit(ToastDismissReason.timeout);
          }
        })
        ..forward();
    }
  }

  void _haptic() {
    // Spec v4 §08: light-tap on success, medium on error.
    switch (widget.spec.variant) {
      case ToastVariant.success:
        HapticFeedback.lightImpact();
      case ToastVariant.error:
        HapticFeedback.mediumImpact();
      case ToastVariant.warning:
        HapticFeedback.mediumImpact();
      case ToastVariant.info:
      case ToastVariant.promo:
        HapticFeedback.selectionClick();
      case ToastVariant.loading:
        break;
    }
  }

  /// Plays the exit animation, then asks the host to remove the pill.
  void requestExit(ToastDismissReason reason) {
    if (_exiting) return;
    _exiting = true;
    _hold?.stop();
    _pulse.stop();
    _exit.forward().whenComplete(() {
      widget.onGone(this);
      widget.onClosed(reason);
    });
  }

  void _handleTap() {
    final onTap = widget.spec.onTap;
    if (onTap == null) return;
    HapticFeedback.selectionClick();
    onTap();
    requestExit(ToastDismissReason.action);
  }

  bool get _canSnooze =>
      widget.spec.duration != null &&
      widget.spec.variant != ToastVariant.error &&
      widget.spec.variant != ToastVariant.loading;

  @override
  void dispose() {
    widget.onGone(this);
    _enter.dispose();
    _exit.dispose();
    _pulse.dispose();
    _spin?.dispose();
    _hold?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final brightness = Theme.of(context).brightness;
    final tokens = _PillTokens.of(brightness);
    final dot = _dotColor(spec.variant);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.88;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final pill = ConstrainedBox(
      constraints: BoxConstraints(minWidth: 168, maxWidth: maxWidth),
      child: IntrinsicWidth(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 32,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                // Inner top sheen (dark theme only).
                if (tokens.highlight.a > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [tokens.highlight, Colors.transparent],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),
                  ),
                spec.builder != null
                    ? spec.builder!(context)
                    : _PillBody(spec: spec, tokens: tokens, dot: dot, pulse: _pulse, spin: _spin, onAction: requestExit),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap routes (if onTap supplied); press pauses the auto-dismiss timer.
    Widget interactive = Listener(
      onPointerDown: (_) {
        if (!_exiting) _hold?.stop();
      },
      onPointerUp: (_) {
        if (!_exiting) _hold?.forward();
      },
      onPointerCancel: (_) {
        if (!_exiting) _hold?.forward();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: pill,
      ),
    );

    // Swipe up to dismiss (Spec v4 §05).
    Widget body = Dismissible(
      key: ValueKey('${spec.id}_up'),
      direction: DismissDirection.up,
      resizeDuration: null,
      onDismissed: (_) {
        widget.onGone(this);
        widget.onClosed(ToastDismissReason.swipe);
      },
      child: interactive,
    );

    // Swipe right to snooze 60 s (non-error states only).
    if (_canSnooze) {
      final snoozeSpec = spec;
      body = Dismissible(
        key: ValueKey('${spec.id}_rt'),
        direction: DismissDirection.startToEnd,
        resizeDuration: null,
        onDismissed: (_) {
          widget.onGone(this);
          widget.onClosed(ToastDismissReason.swipe);
          Timer(const Duration(seconds: 60),
              () => DrivlyToast._show(snoozeSpec));
        },
        child: body,
      );
    }

    return Semantics(
      liveRegion: true,
      container: true,
      label: '${spec.variant.name} ${spec.title}. ${spec.message ?? ''}',
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _exit]),
        builder: (_, child) {
          final double opacity, scale, dy;
          if (_exiting) {
            final e = _exitCurve.value;
            opacity = (1 - e).clamp(0.0, 1.0);
            scale = reduce ? 1.0 : 1.0 - 0.4 * e; // 1.0 → 0.6
            dy = reduce ? 0.0 : -10.0 * e; // 0 → −10
          } else {
            opacity = _opacityIn.value.clamp(0.0, 1.0);
            scale = reduce ? 1.0 : _scaleIn.value;
            dy = reduce ? 0.0 : _yIn.value;
          }
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Material(color: Colors.transparent, child: body),
      ),
    );
  }
}

/// The default single/two-line pill content: status dot · title (· subtext).
class _PillBody extends StatelessWidget {
  final _ToastSpec spec;
  final _PillTokens tokens;
  final Color dot;
  final AnimationController pulse;
  final AnimationController? spin;
  final void Function(ToastDismissReason) onAction;

  const _PillBody({
    required this.spec,
    required this.tokens,
    required this.dot,
    required this.pulse,
    required this.spin,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasSub = spec.message != null && spec.message!.isNotEmpty;
    return ConstrainedBox(
      // 42 pt single-line · 56 pt with subtext (Spec v4 §02).
      constraints: BoxConstraints(minHeight: hasSub ? 56 : 42),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 18, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StatusDot(color: dot, pulse: pulse, spin: spin),
            const SizedBox(width: 10), // dot → text spacing
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: tokens.text,
                      fontSize: 13.5,
                      height: 15 / 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.14, // -0.01em
                    ),
                  ),
                  if (hasSub) ...[
                    const SizedBox(height: 1),
                    Text(
                      spec.message!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: tokens.subtext,
                        fontSize: 11.5,
                        height: 13 / 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (spec.action != null) ...[
              const SizedBox(width: 12),
              _PillAction(
                label: spec.action!.label,
                color: dot,
                onTap: () {
                  spec.action!.onTap();
                  onAction(ToastDismissReason.action);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Solid semantic dot with a soft glow halo and a "live" pulse ring. For the
/// loading variant it becomes a small spinner.
class _StatusDot extends StatelessWidget {
  final Color color;
  final AnimationController pulse;
  final AnimationController? spin;
  const _StatusDot({required this.color, required this.pulse, this.spin});

  @override
  Widget build(BuildContext context) {
    if (spin != null) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    final tokens = _PillTokens.of(Theme.of(context).brightness);
    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Expanding "live" ring: opacity 0.55 → 0, radius +8px, 1.6 s loop.
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final t = pulse.value;
                final size = 11.0 + 16.0 * t;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.55 * (1 - t)),
                  ),
                );
              },
            ),
            // Core dot + glow halo.
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: tokens.glowAlpha),
                    blurRadius: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillAction(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
