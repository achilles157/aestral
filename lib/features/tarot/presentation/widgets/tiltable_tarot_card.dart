import 'package:flutter/material.dart';

class PulsingAura extends StatefulWidget {
  final Widget child;
  final Color glowColor;

  const PulsingAura({super.key, required this.child, required this.glowColor});

  @override
  State<PulsingAura> createState() => _PulsingAuraState();
}

class _PulsingAuraState extends State<PulsingAura> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 8.0, end: 28.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.3),
                blurRadius: _animation.value,
                spreadRadius: _animation.value * 0.1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class TiltableTarotCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;

  const TiltableTarotCard({
    super.key,
    required this.child,
    this.width = 250,
    this.height = 400,
  });

  @override
  State<TiltableTarotCard> createState() => _TiltableTarotCardState();
}

class _TiltableTarotCardState extends State<TiltableTarotCard> with SingleTickerProviderStateMixin {
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  
  late AnimationController _resetController;
  late Animation<double> _resetXAnimation;
  late Animation<double> _resetYAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      setState(() {
        _rotateX = _resetXAnimation.value;
        _rotateY = _resetYAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_resetController.isAnimating) _resetController.stop();
    final dx = details.localPosition.dx - (size.width / 2);
    final dy = details.localPosition.dy - (size.height / 2);
    setState(() {
      _rotateX = (dy / (size.height / 2)).clamp(-1.0, 1.0) * -0.22;
      _rotateY = (dx / (size.width / 2)).clamp(-1.0, 1.0) * 0.22;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _resetXAnimation = Tween<double>(begin: _rotateX, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetYAnimation = Tween<double>(begin: _rotateY, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.reset();
    _resetController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = Size(widget.width, widget.height);

    return GestureDetector(
      onPanUpdate: (details) => _onPanUpdate(details, cardSize),
      onPanEnd: _onPanEnd,
      child: MouseRegion(
        onHover: (event) {
          if (_resetController.isAnimating) _resetController.stop();
          final dx = event.localPosition.dx - (cardSize.width / 2);
          final dy = event.localPosition.dy - (cardSize.height / 2);
          setState(() {
            _rotateX = (dy / (cardSize.height / 2)).clamp(-1.0, 1.0) * -0.22;
            _rotateY = (dx / (cardSize.width / 2)).clamp(-1.0, 1.0) * 0.22;
          });
        },
        onExit: (_) {
          _resetXAnimation = Tween<double>(begin: _rotateX, end: 0.0).animate(
            CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
          );
          _resetYAnimation = Tween<double>(begin: _rotateY, end: 0.0).animate(
            CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
          );
          _resetController.reset();
          _resetController.forward();
        },
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotateX)
            ..rotateY(_rotateY),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
