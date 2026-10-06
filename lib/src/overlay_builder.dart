part of 'paginated_typeahead.dart';

class _OverlayBuilder extends StatefulWidget {
  final Widget Function(Size, VoidCallback hide) overlay;
  final Widget Function(VoidCallback show) child;
  final OverlayPortalController? overlayPortalController;

  const _OverlayBuilder({
    required this.overlay,
    required this.child,
    this.overlayPortalController,
  });

  @override
  State<_OverlayBuilder> createState() => _OverlayBuilderState();
}

class _OverlayBuilderState extends State<_OverlayBuilder> {
  late OverlayPortalController overlayController;

  @override
  void initState() {
    super.initState();
    overlayController =
        widget.overlayPortalController ?? OverlayPortalController();
  }

  void showOverlay() => overlayController.show();

  void hideOverlay() => overlayController.hide();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (_) {
        final renderBox = context.findRenderObject() as RenderBox;
        return widget.overlay(renderBox.size, hideOverlay);
      },
      child: widget.child(showOverlay),
    );
  }
}
