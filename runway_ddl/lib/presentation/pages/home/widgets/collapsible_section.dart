import 'package:flutter/material.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final Widget Function(BuildContext context) builder;
  final Color? titleColor;
  final IconData? icon;
  final Color? iconColor;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.initiallyExpanded = true,
    required this.builder,
    this.titleColor,
    this.icon,
    this.iconColor,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleExpansion,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.iconColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.titleColor ?? Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _iconTurns,
                  child: const Icon(Icons.expand_more, size: 24),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.builder(context),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
