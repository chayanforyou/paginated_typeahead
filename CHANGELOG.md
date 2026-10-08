## 2.0.0

**Breaking changes**

* Removed `inputDecoration`, `hintText`, `validator`, `autovalidateMode`, `keyboardType` and `inputFormatters`. Use `builder` to provide a custom text field instead.
* Changed the default `debounceDuration` from `600ms` to `300ms`.

**Fixes**

* Fixed load-more results from a previous query being appended to a new query's results.
* Fixed the dropdown staying open after unfocus when an item was selected with the mouse.
* Fixed `SuggestionsController.open()` showing an endless loading indicator after an in-flight search was hidden.
* Fixed `SuggestionsController.open()` searching with untrimmed text.
* Fixed the dropdown position and height not updating when the text field scrolls.

## 1.3.0

* Added `hideOnEmpty` property to automatically hide the dropdown when results are empty.
* Fixed dropdown collapsing to zero height when placed inside a nested `Scrollable` or `ListView`.
* Fixed unwanted gap between the software keyboard and dropdown overlay.
* Added `Clip.hardEdge` to default `Card` container so content respects rounded borders.
* Refined dropdown footer and pagination loader padding.

## 1.2.0

* Updated default dropdown container to use `Card` widget with theme-defined elevation, shape, and card color.

## 1.1.0

* Added `decorationBuilder` and `clearOnSelect`.
* Added dedicated typedefs.
* Performance optimizations.

## 1.0.0

* Initial release.
