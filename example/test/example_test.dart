import 'package:flutter_test/flutter_test.dart';
import 'package:paginated_typeahead_example/main.dart';

void main() {
  testWidgets('renders App demo', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });
}
