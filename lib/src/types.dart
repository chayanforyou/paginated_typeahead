import 'dart:async';

import 'package:flutter/widgets.dart';

/// Called to retrieve paginated suggestions for [query] and [page].
///
/// Returns a record of `(List<T>? items, bool hasMore)`.
typedef PaginatedSuggestionsCallback<T>
    = FutureOr<(List<T>? items, bool hasMore)> Function(String query, int page);

/// Builds a widget for a suggestion in the suggestions box.
typedef SuggestionsItemBuilder<T> = Widget Function(T value);

/// Called when a suggestion is selected.
typedef SuggestionSelectionCallback<T> = void Function(T suggestion);

/// Builds a widget for the error in the suggestions box.
typedef SuggestionsErrorBuilder = Widget Function(
  BuildContext context,
  Object? error,
);

/// Builds the retry widget when loading the next page fails.
typedef LoadMoreErrorBuilder = Widget Function(
  BuildContext context,
  VoidCallback retry,
);

/// Builds the text field of the suggestions field.
///
/// Both the [controller] and [focusNode] must be passed to the text field.
typedef SuggestionsFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
);

/// Builds the decoration of the suggestions box.
typedef SuggestionsDecorationBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// Builds the animation for opening and closing the suggestions box.
typedef SuggestionsAnimationBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);

/// Builds the list of suggestions in the suggestions box.
///
/// [children] is the list of suggestions to display built by [itemBuilder].
typedef SuggestionsListBuilder = Widget Function(
  BuildContext context,
  List<Widget> children,
);
