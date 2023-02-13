part of '../flutter_advanced_drawer.dart';

/// AdvancedDrawer widget.
class AdvancedDrawer extends StatefulWidget {
  const AdvancedDrawer({
    Key? key,
    required this.child,
    required this.drawer,
    required this.controller,
    this.backdropColor,
    this.openRatio = 0.75,
    this.openScale = 0.85,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve,
    this.childDecoration,
    this.animateChildDecoration = true,
    this.rtlOpening = false,
    this.disabledGestures = false,
    this.animationController,
  }) : super(key: key);

  /// Child widget. (Usually widget that represent a screen)
  final Widget child;

  /// Drawer widget. (Widget behind the [child]).
  final Widget drawer;

  /// Controller that controls widget state.
  final AdvancedDrawerController controller;

  /// Backdrop color.
  final Color? backdropColor;

  /// Opening ratio.
  final double openRatio;

  /// Opening ratio.
  final double openScale;

  /// Animation duration.
  final Duration animationDuration;

  /// Animation curve.
  final Curve? animationCurve;

  /// Child container decoration in open widget state.
  final BoxDecoration? childDecoration;

  /// Indicates that [childDecoration] might be animated or not.
  /// NOTICE: It may cause animation jerks.
  final bool animateChildDecoration;

  /// Opening from Right-to-left.
  final bool rtlOpening;

  /// Disable gestures.
  final bool disabledGestures;

  /// Controller that controls widget animation.
  final AnimationController? animationController;

  @override
  _AdvancedDrawerState createState() => _AdvancedDrawerState();
}

class _AdvancedDrawerState extends State<AdvancedDrawer>
    with SingleTickerProviderStateMixin {
  late final AdvancedDrawerController _controller;
  late AnimationController _animationController;
  late Animation<double> _drawerScaleAnimation;
  late Animation<Offset> _childSlideAnimation;
  late Animation<double> _childScaleAnimation;
  late Animation<Decoration> _childDecorationAnimation;
  late double _offsetValue;
  late Offset _freshPosition;
  bool _captured = false;
  Offset? _startPosition;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;
    _controller.addListener(_handleControllerChanged);

    _animationController = widget.animationController ??
        AnimationController(
          vsync: this,
          value: _controller.value.visible ? 1 : 0,
        );

    _animationController.duration = widget.animationDuration;

    buildAnimation();
  }

  void buildAnimation() {
    final parentAnimation = widget.animationCurve == null
        ? _animationController
        : CurvedAnimation(
            curve: widget.animationCurve!,
            parent: _animationController,
          );

    _drawerScaleAnimation = Tween<double>(
      begin: widget.openRatio,
      end: 1.0,
    ).animate(parentAnimation);

    _childSlideAnimation = Tween<Offset>(
      begin: Offset(_controller.expanded ? widget.openRatio : 0, 0),
      end: Offset(_controller.expanded ? 1 : widget.openRatio, 0),
    ).animate(parentAnimation);

    _childScaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.openScale,
    ).animate(parentAnimation);

    _childDecorationAnimation = DecorationTween(
      begin: const BoxDecoration(),
      end: widget.childDecoration,
    ).animate(parentAnimation);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backdropColor,
      child: IgnorePointer(
        ignoring: widget.disabledGestures,
        child: GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          onHorizontalDragCancel: _handleDragCancel,
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Align(
                  alignment: widget.rtlOpening
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ValueListenableBuilder<dynamic>(
                      valueListenable: _controller,
                      builder: (context, snapshot, _) {
                        return FractionallySizedBox(
                          widthFactor:
                              _controller.expanded ? 1 : widget.openRatio,
                          child: ScaleTransition(
                            scale: _drawerScaleAnimation,
                            alignment: widget.rtlOpening
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: widget.drawer,
                          ),
                        );
                      }),
                ),
                SlideTransition(
                  position: _childSlideAnimation,
                  textDirection:
                      widget.rtlOpening ? TextDirection.rtl : TextDirection.ltr,
                  child: ScaleTransition(
                    scale: _childScaleAnimation,
                    child: Builder(
                      builder: (_) {
                        final childStack = Stack(
                          children: [
                            widget.child,
                            ValueListenableBuilder<AdvancedDrawerValue>(
                              valueListenable: _controller,
                              builder: (_, value, __) {
                                if (!value.visible) {
                                  return const SizedBox();
                                }

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _controller.hideDrawer,
                                    highlightColor: Colors.transparent,
                                    child: Container(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );

                        if (widget.animateChildDecoration &&
                            widget.childDecoration != null) {
                          return AnimatedBuilder(
                            animation: _childDecorationAnimation,
                            builder: (_, child) {
                              return Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: _childDecorationAnimation.value,
                                child: child,
                              );
                            },
                            child: childStack,
                          );
                        }

                        return Container(
                          clipBehavior: widget.childDecoration != null
                              ? Clip.antiAlias
                              : Clip.none,
                          decoration: widget.childDecoration,
                          child: childStack,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleControllerChanged() {
    buildAnimation();
    setState(() {});
    _controller.value.visible
        ? _animationController.forward()
        : _animationController.reverse();
  }

  void _handleDragStart(DragStartDetails details) {
    _captured = true;
    _startPosition = details.globalPosition;
    _offsetValue = _animationController.value;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_captured) return;

    final screenSize = MediaQuery.of(context).size;

    _freshPosition = details.globalPosition;

    final diff = (_freshPosition - _startPosition!).dx;

    _animationController.value = _offsetValue +
        (diff / (screenSize.width * widget.openRatio)) *
            (widget.rtlOpening ? -1 : 1);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_captured) return;

    _captured = false;

    if (_animationController.value >= 0.5) {
      if (_controller.value.visible) {
        _animationController.forward();
      } else {
        _controller.showDrawer();
      }
    } else {
      if (!_controller.value.visible) {
        _animationController.reverse();
      } else {
        _controller.hideDrawer();
      }
    }
  }

  void _handleDragCancel() {
    _captured = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);

    if (widget.controller == null) {
      _controller.dispose();
    }

    if (widget.animationController == null) {
      _animationController.dispose();
    }

    super.dispose();
  }
}
