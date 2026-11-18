import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades and lifts [child] into place once, optionally after a [delay], so
/// lists and screens can enter with a soft staggered cascade.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // The delay is part of the controller timeline (not a Timer) so pending
  // delays never outlive the widget tree.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Replays a fade/lift each time [active] turns true, without rebuilding
/// [child]'s state. Used for tabs kept alive in an IndexedStack.
class TabEntrance extends StatefulWidget {
  const TabEntrance({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<TabEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(TabEntrance old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !_reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _curve.value) * 24),
        child: child,
      ),
    ),
  );
}

/// Wraps [children] in a column whose items enter one after another.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 90),
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final Duration step;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++)
        FadeSlideIn(delay: step * i, child: children[i]),
    ],
  );
}

/// Gently floats [child] up and down in a loop.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.distance = 6,
    this.period = const Duration(seconds: 4),
  });

  final Widget child;
  final double distance;
  final Duration period;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        Curves.easeInOut.transform(_controller.value) * -widget.distance,
      ),
      child: child,
    ),
  );
}

/// Soft pink hair-strand waves that drift slowly behind content.
class StrandWaveBackground extends StatefulWidget {
  const StrandWaveBackground({super.key, this.child});

  final Widget? child;

  @override
  State<StrandWaveBackground> createState() => _StrandWaveBackgroundState();
}

class _StrandWaveBackgroundState extends State<StrandWaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(painter: StrandWavePainter(_controller)),
        ),
      ),
      if (widget.child != null) widget.child!,
    ],
  );
}

class StrandWavePainter extends CustomPainter {
  StrandWavePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _strands = [
    (0.18, 0.10, 34.0, 0.0, 3.0, AppColors.rose),
    (0.30, 0.55, 26.0, 1.3, 2.0, AppColors.pink),
    (0.78, 0.35, 40.0, 2.4, 3.5, AppColors.rose),
    (0.90, 0.80, 30.0, 4.0, 2.0, AppColors.pink),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    for (final (yFactor, alpha, amplitude, phase, width, color) in _strands) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: alpha * 0.7);
      final baseY = size.height * yFactor;
      final path = Path()..moveTo(-20, baseY);
      for (var x = -20.0; x <= size.width + 20; x += 8) {
        final u = x / size.width;
        final y =
            baseY +
            math.sin(u * 2 * math.pi + phase + t) * amplitude +
            math.sin(u * 4 * math.pi + phase * 2 - t) * amplitude * 0.25;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(StrandWavePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

/// Pink check badge that pops in with a springy scale to celebrate a
/// completed action such as a logged wash.
class PopBadge extends StatelessWidget {
  const PopBadge({super.key, this.icon = Icons.check_rounded, this.size = 72});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.pink,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );
    if (_reduceMotion(context)) return badge;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: badge,
    );
  }
}
