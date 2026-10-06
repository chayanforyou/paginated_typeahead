import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paginated_typeahead/paginated_typeahead.dart';

void main() {
  group('PaginatedTypeAhead', () {
    testWidgets('renders search field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              itemBuilder: (value) => Text(value),
              suggestionsCallback: (search, page) {
                return (['a', 'b', 'c'], false);
              },
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets(
        'shows suggestions on focus when minCharsForSuggestions is 0 (default)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              itemBuilder: (value) => Text('Item: $value'),
              onSelected: (_) {},
              suggestionsCallback: (search, page) {
                return (['Apple', 'Banana'], false);
              },
            ),
          ),
        ),
      );

      // Tap to focus the search field
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Suggestions should now be displayed
      expect(find.text('Item: Apple'), findsOneWidget);
      expect(find.text('Item: Banana'), findsOneWidget);
    });

    testWidgets(
        'does not show suggestions on focus when minCharsForSuggestions is 3 and field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              minCharsForSuggestions: 3,
              itemBuilder: (value) => Text('Item: $value'),
              onSelected: (_) {},
              suggestionsCallback: (search, page) {
                return (['Doctor Who', 'Doctor Strange'], false);
              },
            ),
          ),
        ),
      );

      // Tap to focus the search field (0 chars < 3)
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Suggestions should not be displayed
      expect(find.text('Item: Doctor Who'), findsNothing);
      expect(find.text('Item: Doctor Strange'), findsNothing);
    });

    testWidgets(
        'shows suggestions when input reaches minCharsForSuggestions and hides when below',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              minCharsForSuggestions: 3,
              debounceDuration: Duration.zero,
              itemBuilder: (value) => Text('Item: $value'),
              emptyBuilder: (_) => const Text('No items found'),
              suggestionsCallback: (query, page) {
                return (['Doctor Who', 'Doctor Strange'], false);
              },
            ),
          ),
        ),
      );

      // 1. Tap on empty search field (length 0 < 3) -> should NOT open overlay
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('Item: Doctor Who'), findsNothing);

      // 2. Type 2 characters 'Do' -> still < 3, should NOT open overlay, but text must be preserved
      await tester.enterText(find.byType(TextFormField), 'Do');
      await tester.pumpAndSettle();

      expect(find.text('Do'), findsOneWidget);
      expect(find.text('Item: Doctor Who'), findsNothing);

      // 3. Type 3rd character 'Doc' -> now >= 3, should open overlay with items
      await tester.enterText(find.byType(TextFormField), 'Doc');
      await tester.pumpAndSettle();

      expect(find.text('Doc'), findsOneWidget);
      expect(find.text('Item: Doctor Who'), findsOneWidget);
      expect(find.text('Item: Doctor Strange'), findsOneWidget);

      // 4. Backspace to 'Do' -> drops below 3, should hide overlay but preserve text
      await tester.enterText(find.byType(TextFormField), 'Do');
      await tester.pumpAndSettle();

      expect(find.text('Do'), findsOneWidget);
      expect(find.text('Item: Doctor Who'), findsNothing);
    });

    testWidgets('pointer scroll over dropdown does not hide overlay and triggers pagination',
        (WidgetTester tester) async {
      int pageLoaded = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              itemBuilder: (value) => SizedBox(height: 50, child: Text('Item: $value')),
              suggestionsCallback: (query, page) {
                pageLoaded = page;
                if (page == 0) {
                  return (List.generate(10, (i) => 'Page0-$i'), true);
                } else {
                  return (List.generate(10, (i) => 'Page1-$i'), false);
                }
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('Item: Page0-0'), findsOneWidget);

      // Simulate mouse scroll down over the list
      await tester.drag(find.text('Item: Page0-0'), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Overlay should still be visible and next page loaded
      expect(pageLoaded, 1);
      expect(find.text('Item: Page1-0'), findsOneWidget);
    });

    testWidgets('mouse wheel scroll over dropdown triggers pagination',
        (WidgetTester tester) async {
      int pageLoaded = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              itemBuilder: (value) => SizedBox(height: 50, child: Text('Item: $value')),
              suggestionsCallback: (query, page) {
                pageLoaded = page;
                if (page == 0) {
                  return (List.generate(10, (i) => 'Page0-$i'), true);
                } else {
                  return (List.generate(10, (i) => 'Page1-$i'), false);
                }
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('Item: Page0-0'), findsOneWidget);

      // Send mouse wheel scroll event
      final target = tester.getCenter(find.text('Item: Page0-0'));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: target,
          scrollDelta: const Offset(0, 500),
        ),
      );
      await tester.pumpAndSettle();

      expect(pageLoaded, 1);
      expect(find.text('Item: Page1-0'), findsOneWidget);
    });

    testWidgets('dropdown follows dark theme', (WidgetTester tester) async {
      final darkTheme = ThemeData.dark(useMaterial3: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              itemBuilder: (value) => ListTile(title: Text(value)),
              suggestionsCallback: (query, page) {
                return (['DarkItem'], false);
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('DarkItem'), findsOneWidget);

      // Verify the dropdown Material color matches theme surface color (not hardcoded white)
      final materialFinder = find.descendant(
        of: find.byType(OverlayPortal),
        matching: find.byType(Material),
      );
      final materials = tester.widgetList<Material>(materialFinder);
      expect(
        materials.any((m) => m.color == darkTheme.colorScheme.surface),
        isTrue,
      );
    });

    testWidgets(
        'constrainWidth = false does not clip off-screen with negative offset',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(32),
              child: PaginatedTypeAhead<String>(
                initialPage: 0,
                constrainWidth: false,
                offset: const Offset(-12, 5),
                itemBuilder: (value) => ListTile(title: Text(value)),
                suggestionsCallback: (query, page) {
                  return (['UnconstrainedItem'], false);
                },
              ),
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('UnconstrainedItem'), findsOneWidget);

      final materialFinder = find.descendant(
        of: find.byType(OverlayPortal),
        matching: find.byType(Material),
      );
      final dropdownTopLeft = tester.getTopLeft(materialFinder);
      expect(dropdownTopLeft.dx, greaterThanOrEqualTo(0.0));
    });

    testWidgets('hideOnSelect = false keeps overlay open after item selection',
        (WidgetTester tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              hideOnSelect: false,
              hideOnUnfocus: true,
              itemBuilder: (value) => ListTile(title: Text(value)),
              onSelected: (value) => selected = value,
              suggestionsCallback: (query, page) {
                return (['Item1', 'Item2'], false);
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('Item1'), findsOneWidget);

      // Tap Item1
      await tester.tap(find.text('Item1'));
      await tester.pumpAndSettle();

      expect(selected, 'Item1');
      // Overlay must still be open
      expect(find.text('Item2'), findsOneWidget);
    });

    testWidgets('flips above when spaceBelow crosses autoFlipMinHeight and autoFlipDirection is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 50,
                child: PaginatedTypeAhead<String>(
                  initialPage: 0,
                  autoFlipDirection: true,
                  autoFlipMinHeight: 100,
                  itemBuilder: (value) => ListTile(title: Text(value)),
                  suggestionsCallback: (query, page) {
                    return (['FlippedItem'], false);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('FlippedItem'), findsOneWidget);

      final fieldRect = tester.getRect(find.byType(TextFormField));
      final itemRect = tester.getRect(find.text('FlippedItem'));
      // The item should be displayed above the text field
      expect(itemRect.bottom, lessThan(fieldRect.top));
    });

    testWidgets('reflects direction change immediately while dropdown is open',
        (WidgetTester tester) async {
      final directionNotifier = ValueNotifier<VerticalDirection>(VerticalDirection.down);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder<VerticalDirection>(
                valueListenable: directionNotifier,
                builder: (context, direction, _) {
                  return PaginatedTypeAhead<String>(
                    initialPage: 0,
                    direction: direction,
                    autoFlipDirection: false,
                    itemBuilder: (value) => ListTile(title: Text(value)),
                    suggestionsCallback: (query, page) {
                      return (['DynamicItem'], false);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open dropdown with direction = down
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('DynamicItem'), findsOneWidget);
      var fieldRect = tester.getRect(find.byType(TextFormField));
      var itemRect = tester.getRect(find.text('DynamicItem'));
      expect(itemRect.top, greaterThan(fieldRect.bottom));

      // Change direction to up while dropdown is still open
      directionNotifier.value = VerticalDirection.up;
      await tester.pumpAndSettle();

      // Dropdown should still be visible and now placed above the text field
      expect(find.text('DynamicItem'), findsOneWidget);
      fieldRect = tester.getRect(find.byType(TextFormField));
      itemRect = tester.getRect(find.text('DynamicItem'));
      expect(itemRect.bottom, lessThan(fieldRect.top));
    });

    testWidgets('reflects autoFlipDirection change immediately while dropdown is open',
        (WidgetTester tester) async {
      final autoFlipNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 480),
              child: ValueListenableBuilder<bool>(
                valueListenable: autoFlipNotifier,
                builder: (context, autoFlip, _) {
                  return PaginatedTypeAhead<String>(
                    initialPage: 0,
                    direction: VerticalDirection.down,
                    autoFlipDirection: autoFlip,
                    autoFlipMinHeight: 150,
                    itemBuilder: (value) => ListTile(title: Text(value)),
                    suggestionsCallback: (query, page) {
                      return (['AutoFlipDynamicItem'], false);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open dropdown with autoFlipDirection = false
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('AutoFlipDynamicItem'), findsOneWidget);
      var fieldRect = tester.getRect(find.byType(TextFormField));
      var itemRect = tester.getRect(find.text('AutoFlipDynamicItem'));
      // Initially not flipped (placed below the field)
      expect(itemRect.top, greaterThanOrEqualTo(fieldRect.bottom));

      // Toggle autoFlipDirection to true while open
      autoFlipNotifier.value = true;
      await tester.pumpAndSettle();

      // Dropdown should immediately flip above the field
      expect(find.text('AutoFlipDynamicItem'), findsOneWidget);
      fieldRect = tester.getRect(find.byType(TextFormField));
      itemRect = tester.getRect(find.text('AutoFlipDynamicItem'));
      expect(itemRect.bottom, lessThan(fieldRect.top));
    });

    testWidgets('Direction change from down to up in Column updates immediately',
        (WidgetTester tester) async {
      final directionNotifier =
          ValueNotifier<VerticalDirection>(VerticalDirection.down);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<VerticalDirection>(
              valueListenable: directionNotifier,
              builder: (context, direction, _) {
                return Column(
                  mainAxisAlignment: direction == VerticalDirection.up
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: PaginatedTypeAhead<String>(
                        initialPage: 0,
                        direction: direction,
                        autoFlipDirection: true,
                        itemBuilder: (value) => ListTile(title: Text(value)),
                        suggestionsCallback: (query, page) {
                          return (['DirectionItem'], false);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('DirectionItem'), findsOneWidget);
      var fieldRect = tester.getRect(find.byType(TextFormField));
      var itemRect = tester.getRect(find.text('DirectionItem'));
      expect(itemRect.top, greaterThan(fieldRect.bottom));

      directionNotifier.value = VerticalDirection.up;
      await tester.pumpAndSettle();

      expect(find.text('DirectionItem'), findsOneWidget);
      fieldRect = tester.getRect(find.byType(TextFormField));
      itemRect = tester.getRect(find.text('DirectionItem'));
      expect(itemRect.bottom, lessThan(fieldRect.top));
    });

    testWidgets('PaginatedTypeAhead handles null items in suggestionsCallback gracefully',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              suggestionsCallback: (query, page) {
                return (null, false);
              },
              itemBuilder: (item) => Text(item),
              emptyBuilder: (context) => const Text('No items found'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets(
        'PaginatedTypeAhead custom builder renders and triggers suggestions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              builder: (context, ctrl, focus) {
                return TextField(
                  key: const ValueKey('custom_search_field'),
                  controller: ctrl,
                  focusNode: focus,
                  decoration: const InputDecoration(hintText: 'Custom search'),
                );
              },
              suggestionsCallback: (query, page) {
                return (['Custom 1', 'Custom 2'], false);
              },
              itemBuilder: (item) => Text(item),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('custom_search_field')),
        findsOneWidget,
      );
      expect(find.text('Custom search'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('custom_search_field')));
      await tester.pumpAndSettle();

      expect(find.text('Custom 1'), findsOneWidget);
      expect(find.text('Custom 2'), findsOneWidget);
    });

    testWidgets('PaginatedTypeAhead decorationBuilder wraps dropdown box',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              decorationBuilder: (context, child) => Container(
                key: const ValueKey('custom_dropdown_container'),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              ),
              suggestionsCallback: (query, page) {
                return (['Decorated 1', 'Decorated 2'], false);
              },
              itemBuilder: (item) => Text(item),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('custom_dropdown_container')),
        findsOneWidget,
      );
      expect(find.text('Decorated 1'), findsOneWidget);
      expect(find.text('Decorated 2'), findsOneWidget);
    });

    testWidgets('PaginatedTypeAhead clearOnSelect clears search text on item selection',
        (tester) async {
      final controller = TextEditingController(text: 'Item');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedTypeAhead<String>(
              initialPage: 0,
              controller: controller,
              clearOnSelect: true,
              suggestionsCallback: (query, page) {
                return (['Item A', 'Item B'], false);
              },
              itemBuilder: (item) => Text(item),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(controller.text, 'Item');

      await tester.tap(find.text('Item A'));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });
  });
}