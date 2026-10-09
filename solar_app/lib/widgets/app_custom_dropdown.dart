import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? subtitle;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
  });
}

class AppCustomDropdown<T> extends StatefulWidget {
  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final String? label;
  final Widget? headerTrailing;
  final String? hint;
  final IconData? prefixIcon;

  const AppCustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.headerTrailing,
    this.hint,
    this.prefixIcon,
  });

  @override
  State<AppCustomDropdown<T>> createState() => _AppCustomDropdownState<T>();
}

class _AppCustomDropdownState<T> extends State<AppCustomDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animationController.forward();
  }

  void _closeDropdown() {
    _animationController.reverse().then((_) {
      _removeOverlay();
      if (mounted) setState(() => _isOpen = false);
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  AppDropdownItem<T>? get _selectedItem {
    try {
      return widget.items.firstWhere((item) => item.value == widget.value);
    } catch (_) {
      return widget.items.isNotEmpty ? widget.items.first : null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Fullscreen transparent barrier to dismiss on outside click
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            // Floating Dropdown menu positioned right below the input box
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 6),
                child: Material(
                  color: Colors.transparent,
                  child: FadeTransition(
                    opacity: _expandAnimation,
                    child: SizeTransition(
                      sizeFactor: _expandAnimation,
                      axisAlignment: -1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.ink.withValues(alpha: 0.18),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x28000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.items.map((item) {
                                final isSelected = item.value == widget.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: InkWell(
                                    onTap: () {
                                      widget.onChanged(item.value);
                                      _closeDropdown();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.sun.withValues(alpha: 0.28)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: isSelected
                                            ? Border.all(
                                                color: AppColors.sun,
                                                width: 1.2,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          if (item.icon != null) ...[
                                            Icon(
                                              item.icon,
                                              size: 19,
                                              color: isSelected ? AppColors.ink : AppColors.muted,
                                            ),
                                            const SizedBox(width: 10),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.label,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                                if (item.subtitle != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.subtitle!,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 19,
                                              color: AppColors.teal,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _selectedItem;

    final triggerBox = CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen ? AppColors.ink : AppColors.creamDark,
              width: _isOpen ? 1.6 : 1.2,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (item?.icon != null || widget.prefixIcon != null) ...[
                Icon(
                  item?.icon ?? widget.prefixIcon,
                  size: 20,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item?.label ?? widget.hint ?? 'Select',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.label == null) {
      return triggerBox;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            if (widget.headerTrailing != null) widget.headerTrailing!,
          ],
        ),
        const SizedBox(height: 6),
        triggerBox,
      ],
    );
  }
}
