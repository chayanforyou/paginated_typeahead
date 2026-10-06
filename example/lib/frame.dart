import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:paginated_typeahead_example/options.dart';

class MaterialFrame extends StatefulWidget {
  const MaterialFrame({
    super.key,
    required this.exampleBuilder,
    required this.settingsBuilder,
  });

  final Widget Function(
    BuildContext context,
    TextEditingController controller,
    FieldSettings settings,
  ) exampleBuilder;

  final Widget Function(
    BuildContext context,
    TextEditingController controller,
    FieldSettings settings,
  ) settingsBuilder;

  @override
  State<MaterialFrame> createState() => _MaterialFrameState();
}

class _MaterialFrameState extends State<MaterialFrame> {
  final TextEditingController settingsController = TextEditingController();
  final TextEditingController exampleController = TextEditingController();
  final FieldSettings settings = FieldSettings();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: settings.darkMode.value
                  ? Brightness.dark
                  : Brightness.light,
              useMaterial3: true,
            ),
            scrollBehavior:
                const MaterialScrollBehavior().copyWith(dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
            }),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Paginated TypeAhead Demo'),
                actions: [
                  ListenableBuilder(
                    listenable: DefaultTabController.of(context),
                    builder: (context, child) {
                      if (DefaultTabController.of(context).index == 0) {
                        return TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () =>
                              DefaultTabController.of(context).animateTo(1),
                          label: const Text('Settings'),
                        );
                      } else {
                        return TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () =>
                              DefaultTabController.of(context).animateTo(0),
                          label: const Text('Demo'),
                        );
                      }
                    },
                  ),
                ],
              ),
              body: GestureDetector(
                onTap: () => primaryFocus?.unfocus(),
                child: TabBarView(
                  children: [
                    _OverlayTab(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Builder(
                            builder: (tabContext) => widget.exampleBuilder(
                              tabContext,
                              exampleController,
                              settings,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _OverlayTab(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Builder(
                            builder: (tabContext) => widget.settingsBuilder(
                              tabContext,
                              settingsController,
                              settings,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverlayTab extends StatefulWidget {
  const _OverlayTab({required this.child});

  final Widget child;

  @override
  State<_OverlayTab> createState() => _OverlayTabState();
}

class _OverlayTabState extends State<_OverlayTab> {
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = OverlayEntry(builder: _build);
  }

  @override
  void didUpdateWidget(covariant _OverlayTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  Widget _build(BuildContext context) {
    return widget.child;
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
