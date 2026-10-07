import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui';

export 'types.dart';
import 'types.dart';

part 'overlay_builder.dart';

/// Vertical gap between the text field and the dropdown overlay.
const double _kDropdownGap = 8.0;

/// A custom autocomplete search field with pagination support.
///
/// Searches items as the user types and loads more
/// results when scrolling to the bottom of the dropdown.
///
/// Uses [_OverlayBuilder] for declarative overlay management — the dropdown
/// rebuilds automatically with [setState], eliminating manual
/// insert/remove lifecycle handling.
class PaginatedTypeAhead<T> extends StatefulWidget {
  /// Callback when an item is selected.
  final SuggestionSelectionCallback<T>? onSelected;

  /// Builds each result item in the dropdown list.
  final SuggestionsItemBuilder<T> itemBuilder;

  /// Optional builder for a widget to separate items in the dropdown list.
  ///
  /// Defaults to null (no separator).
  final IndexedWidgetBuilder? separatorBuilder;

  /// Optional builder for displaying a widget while suggestions are loading.
  final WidgetBuilder? loadingBuilder;

  /// Optional builder for displaying a widget when no suggestions are found.
  final WidgetBuilder? emptyBuilder;

  /// Optional builder for displaying a widget when fetching suggestions fails.
  final SuggestionsErrorBuilder? errorBuilder;

  /// Optional builder for the progress indicator shown at the bottom when loading the next page.
  final WidgetBuilder? loadMoreLoadingBuilder;

  /// Optional builder for the retry widget shown at the bottom when loading the next page fails.
  final LoadMoreErrorBuilder? loadMoreErrorBuilder;

  /// Callback to fetch suggestions for a search query.
  /// Returns a record of `(List<T>? items, bool hasMore)`.
  final PaginatedSuggestionsCallback<T> suggestionsCallback;

  /// The initial page number to load when fetching suggestions.
  final int initialPage;

  /// Hint text for the search field.
  final String hintText;

  /// Duration to wait before trigger search callback after user stops typing.
  final Duration debounceDuration;

  /// The minimum number of characters required before suggestions are searched and displayed.
  ///
  /// Defaults to 0.
  final int minCharsForSuggestions;

  /// The preferred vertical direction to open the suggestions dropdown.
  ///
  /// Defaults to [VerticalDirection.down].
  final VerticalDirection direction;

  /// Whether the dropdown should flip direction (e.g. open above the text field
  /// if space below is constrained, or open below if space above is constrained).
  ///
  /// Defaults to true.
  final bool autoFlipDirection;

  /// Whether the dropdown overlay should be hidden when the text field loses focus.
  final bool hideOnUnfocus;

  /// Whether the dropdown overlay should be hidden when an item is selected.
  final bool hideOnSelect;

  /// Whether the dropdown overlay should be hidden when there are no suggestions.
  ///
  /// Defaults to false.
  final bool hideOnEmpty;

  /// Whether to clear the search text field when an item is selected.
  ///
  /// Defaults to false.
  final bool clearOnSelect;

  /// The minimum vertical space required below the search field to prevent flipping directions.
  final double autoFlipMinHeight;

  /// Constraints for the dropdown overlay.
  final BoxConstraints dropdownConstraints;

  /// Whether the suggestions box should be constrained to the width of the text field.
  ///
  /// Defaults to true.
  final bool constrainWidth;

  /// The offset of the suggestions dropdown overlay.
  ///
  /// The x value is applied symmetrically as horizontal padding (both left and right),
  /// both when [constrainWidth] is true (relative to the text field) and when false (relative to the screen).
  /// The y value offsets vertically (automatically flipped if opened above the text field).
  final Offset? offset;

  /// Text editing controller to control the search field text.
  final TextEditingController? controller;

  /// An optional controller to manually open/close/toggle the suggestions dropdown.
  final SuggestionsController<T>? suggestionsController;

  /// An optional validator function for Form validation.
  final FormFieldValidator<String>? validator;

  /// The autovalidate mode for the form validation.
  final AutovalidateMode? autovalidateMode;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// Optional input formatters to apply to the search field.
  final List<TextInputFormatter>? inputFormatters;

  /// Optional focus node for the search field.
  final FocusNode? focusNode;

  /// Optional custom builder for the search text field.
  ///
  /// If provided, this builder is called to construct the search field instead
  /// of the default [TextFormField].
  /// Both the [controller] and [focusNode] must be passed to the text field.
  final SuggestionsFieldBuilder? builder;

  /// Optional builder for decorating the suggestions dropdown box.
  ///
  /// If null, a default [Card] container with theme elevation and shape is used.
  final SuggestionsDecorationBuilder? decorationBuilder;

  /// Custom input decoration for the search text field.
  ///
  /// If provided, it will be merged with the default suffix icon (clear button)
  /// if the text field has text.
  final InputDecoration? inputDecoration;

  const PaginatedTypeAhead({
    super.key,
    required this.initialPage,
    this.builder,
    this.decorationBuilder,
    this.onSelected,
    required this.itemBuilder,
    this.separatorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    required this.suggestionsCallback,
    this.controller,
    this.focusNode,
    this.suggestionsController,
    this.hintText = 'Search...',
    this.debounceDuration = const Duration(milliseconds: 600),
    this.minCharsForSuggestions = 0,
    this.direction = VerticalDirection.down,
    this.autoFlipDirection = true,
    this.hideOnUnfocus = true,
    this.hideOnSelect = true,
    this.hideOnEmpty = false,
    this.clearOnSelect = true,
    this.autoFlipMinHeight = 84.0,
    this.dropdownConstraints = const BoxConstraints(),
    this.constrainWidth = true,
    this.offset,
    this.validator,
    this.autovalidateMode,
    this.keyboardType,
    this.inputFormatters,
    this.inputDecoration,
  });

  @override
  State<PaginatedTypeAhead<T>> createState() => _PaginatedTypeAheadState<T>();
}

class _PaginatedTypeAheadState<T> extends State<PaginatedTypeAhead<T>>
    with WidgetsBindingObserver {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _keyboardHeight = ValueNotifier(0.0);
  late final ValueNotifier<VerticalDirection> _direction;

  Timer? _debounceTimer;

  bool _isMouseOverDropdown = false;
  List<T> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  String _currentQuery = '';
  late int _currentPage;
  bool _hasMore = false;
  Object? _error;
  String _lastText = '';

  late TextEditingController controller;
  late FocusNode focusNode;

  void _onControllerTextChanged() {
    if (controller.text != _lastText) {
      _lastText = controller.text;
      _onTextChanged(controller.text);
    }
  }

  @override
  void initState() {
    super.initState();
    _direction = ValueNotifier(widget.direction);
    controller = widget.controller ?? TextEditingController();
    focusNode = widget.focusNode ?? FocusNode();

    _currentPage = widget.initialPage;
    _lastText = controller.text;
    controller.addListener(_onControllerTextChanged);
    WidgetsBinding.instance.addObserver(this);
    widget.suggestionsController?._attach(this);
    focusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateKeyboardHeight();
  }

  @override
  void didChangeMetrics() {
    _updateKeyboardHeight();
  }

  void _updateKeyboardHeight() {
    if (mounted) {
      final view = View.of(context);
      _keyboardHeight.value = view.viewInsets.bottom / view.devicePixelRatio;
    }
  }

  @override
  void didUpdateWidget(PaginatedTypeAhead<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.suggestionsController != oldWidget.suggestionsController) {
      oldWidget.suggestionsController?._detach();
      widget.suggestionsController?._attach(this);
    }

    if (oldWidget.controller != widget.controller) {
      controller.removeListener(_onControllerTextChanged);
      if (oldWidget.controller == null) {
        controller.dispose();
      }
      controller = widget.controller ?? TextEditingController();
      _lastText = controller.text;
      controller.addListener(_onControllerTextChanged);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      focusNode.removeListener(_onFocusChanged);
      if (oldWidget.focusNode == null) {
        focusNode.dispose();
      }
      focusNode = widget.focusNode ?? FocusNode();
      focusNode.addListener(_onFocusChanged);
    }

    if (oldWidget.direction != widget.direction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _direction.value = widget.direction;
        }
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerTextChanged);
    focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      controller.dispose();
    }
    if (widget.focusNode == null) {
      focusNode.dispose();
    }

    WidgetsBinding.instance.removeObserver(this);
    widget.suggestionsController?._detach();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _keyboardHeight.dispose();
    _direction.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Overlay visibility helpers
  // ---------------------------------------------------------------------------

  void _showOverlay() {
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _hideOverlay() {
    _debounceTimer?.cancel();
    if (mounted) {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
      setState(() {
        _results = [];
        _currentQuery = '';
        _currentPage = widget.initialPage;
        _hasMore = false;
        _loadMoreFailed = false;
        _error = null;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Focus & scroll listeners
  // ---------------------------------------------------------------------------

  void _onFocusChanged() {
    if (!focusNode.hasFocus) {
      if (widget.hideOnUnfocus) {
        // Delay hiding to allow tap/scroll events on the overlay to fire first.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !focusNode.hasFocus && !_isMouseOverDropdown) {
            _hideOverlay();
          }
        });
      }
    } else {
      final query = controller.text.trim();
      if (query.length >= widget.minCharsForSuggestions) {
        if (query == _currentQuery && _results.isNotEmpty) {
          _showOverlay();
        } else {
          _search(query);
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        !_loadMoreFailed &&
        _hasMore) {
      _loadMore();
    }
  }

  void _handlePointerSignal(PointerSignalEvent pointerSignal) {
    if (pointerSignal is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (
        event,
      ) {
        if (!mounted) return;
        final scrollEvent = event as PointerScrollEvent;
        final deltaY = scrollEvent.scrollDelta.dy;
        if (_scrollController.hasClients && deltaY != 0) {
          final position = _scrollController.position;
          if (position.maxScrollExtent > 0) {
            final targetOffset = (position.pixels + deltaY).clamp(
              0.0,
              position.maxScrollExtent,
            );
            if (targetOffset != position.pixels) {
              _scrollController.jumpTo(targetOffset);
            }
          }
          if (deltaY > 0 &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 100 &&
              !_isLoadingMore &&
              !_loadMoreFailed &&
              _hasMore) {
            _loadMore();
          }
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Search + pagination logic
  // ---------------------------------------------------------------------------

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _error = null;

    final query = value.trim();
    if (query.length < widget.minCharsForSuggestions) {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
      setState(() {
        _results = [];
        _currentQuery = query;
      });
      return;
    }

    _debounceTimer = Timer(widget.debounceDuration, () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.length < widget.minCharsForSuggestions) {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
      return;
    }

    if (query == _currentQuery && _results.isNotEmpty) {
      _showOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuery = query;
      _currentPage = widget.initialPage;
      _results = [];
      _error = null;
      _loadMoreFailed = false;
    });
    _showOverlay();

    try {
      final (items, hasMore) = await widget.suggestionsCallback(
        query,
        widget.initialPage,
      );
      if (mounted && _currentQuery == query) {
        final resultList = items ?? [];
        if (widget.hideOnEmpty && resultList.isEmpty) {
          if (_overlayController.isShowing) {
            _overlayController.hide();
          }
        }
        setState(() {
          _results = resultList;
          _hasMore = hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _currentQuery == query) {
        setState(() {
          _isLoading = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    try {
      final nextPage = _currentPage + 1;
      final (items, hasMore) = await widget.suggestionsCallback(
        _currentQuery,
        nextPage,
      );
      if (mounted) {
        setState(() {
          if (items != null) _results.addAll(items);
          _currentPage = nextPage;
          _hasMore = hasMore;
          _isLoadingMore = false;
          _loadMoreFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _loadMoreFailed = true;
        });
      }
    }
  }

  void _onItemSelected(T item) {
    if (widget.clearOnSelect) {
      controller.clear();
    }
    if (widget.hideOnSelect) {
      focusNode.unfocus();
      _hideOverlay();
    } else {
      if (!focusNode.hasFocus) {
        focusNode.requestFocus();
      }
    }
    widget.onSelected?.call(item);
  }

  // ---------------------------------------------------------------------------
  // Dropdown content (loading / error / empty / results)
  // ---------------------------------------------------------------------------

  Widget _buildDropdownContent() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      if (widget.loadingBuilder != null) {
        return widget.loadingBuilder!(context);
      }
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error);
      }
      return _buildStatusMessage(
        icon: Icons.error_outline_rounded,
        color: colorScheme.onSurfaceVariant,
        message: 'The application has encountered an unknown error.\n'
            'Please try again later.',
      );
    }

    if (_results.isEmpty) {
      if (widget.hideOnEmpty) {
        return const SizedBox.shrink();
      }
      if (widget.emptyBuilder != null) {
        return widget.emptyBuilder!(context);
      }
      return _buildStatusMessage(
        icon: Icons.search_off_rounded,
        color: colorScheme.onSurfaceVariant,
        message: 'No data available',
      );
    }

    final itemCount = _results.length + (_hasMore ? 1 : 0);

    Widget buildItem(BuildContext context, int index) {
      if (index == _results.length) {
        return Listener(
          onPointerSignal: _handlePointerSignal,
          child: _buildLoadMoreIndicator(),
        );
      }
      final item = _results[index];
      return Listener(
        onPointerSignal: _handlePointerSignal,
        child: InkWell(
          canRequestFocus: false,
          onTap: () => _onItemSelected(item),
          child: widget.itemBuilder(item),
        ),
      );
    }

    final listView = widget.separatorBuilder != null
        ? ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            itemCount: itemCount,
            separatorBuilder: (context, index) => Listener(
              onPointerSignal: _handlePointerSignal,
              child: widget.separatorBuilder!(context, index),
            ),
            itemBuilder: buildItem,
          )
        : ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            itemCount: itemCount,
            itemBuilder: buildItem,
          );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 100 &&
            !_isLoadingMore &&
            !_loadMoreFailed &&
            _hasMore) {
          _loadMore();
        }
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
          scrollbars: true,
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: listView,
        ),
      ),
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 46),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurfaceVariant;

    if (_loadMoreFailed) {
      if (widget.loadMoreErrorBuilder != null) {
        return widget.loadMoreErrorBuilder!(context, _loadMore);
      }

      return InkWell(
        onTap: _loadMore,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, color: textColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Retry loading more',
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoadingMore) {
      return const SizedBox.shrink();
    }

    if (widget.loadMoreLoadingBuilder != null) {
      return widget.loadMoreLoadingBuilder!(context);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Positioning & Layout Calculations
  // ---------------------------------------------------------------------------

  _DropdownLayout _calculateDropdownLayout({
    required BuildContext overlayContext,
    required Size anchorSize,
    required double keyboardHeight,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    final verticalGap = widget.offset?.dy ?? _kDropdownGap;
    final horizontalOffset = widget.offset?.dx ?? 0.0;
    bool showAbove = false;
    double targetX = 0.0;
    double maxHeight = widget.dropdownConstraints.maxHeight;

    if (box != null && box.hasSize) {
      final pos = box.localToGlobal(Offset.zero);
      targetX = pos.dx;

      final mq = MediaQuery.of(overlayContext);
      final sTop = mq.padding.top;
      final effectiveKeyboardHeight = math.max(
        keyboardHeight,
        mq.viewInsets.bottom,
      );
      final bottomInset = effectiveKeyboardHeight > 0
          ? effectiveKeyboardHeight
          : mq.padding.bottom;
      final sBottom = mq.size.height - bottomInset;

      final spaceBelow = math.max(0.0, sBottom - (pos.dy + box.size.height));
      final spaceAbove = math.max(0.0, pos.dy - sTop);

      final preferredUp = _direction.value == VerticalDirection.up;
      if (preferredUp) {
        final shouldFlip = widget.autoFlipDirection &&
            spaceAbove < widget.autoFlipMinHeight + verticalGap &&
            spaceBelow > spaceAbove;
        showAbove = !shouldFlip;
      } else {
        final shouldFlip = widget.autoFlipDirection &&
            spaceBelow < widget.autoFlipMinHeight + verticalGap &&
            spaceAbove > spaceBelow;
        showAbove = shouldFlip;
      }

      final available = math.max(
        0.0,
        (showAbove ? spaceAbove : spaceBelow) - verticalGap,
      );
      maxHeight =
          maxHeight.isFinite ? math.min(maxHeight, available) : available;
    }

    final screenWidth = MediaQuery.of(overlayContext).size.width;
    final baseWidth = widget.constrainWidth ? anchorSize.width : screenWidth;
    final inset = widget.constrainWidth
        ? horizontalOffset
        : math.max(0.0, horizontalOffset);
    final width = math.min(
      screenWidth,
      widget.dropdownConstraints.constrainWidth(
        math.max(0.0, baseWidth - inset * 2),
      ),
    );
    final globalX = (widget.constrainWidth ? targetX + horizontalOffset : inset)
        .clamp(0.0, math.max(0.0, screenWidth - width));

    return _DropdownLayout(
      showAbove: showAbove,
      width: width,
      maxHeight: math.max(0.0, maxHeight),
      offset: Offset(globalX - targetX, showAbove ? -verticalGap : verticalGap),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return _OverlayBuilder(
      overlayPortalController: _overlayController,
      overlay: (size, _) {
        return ListenableBuilder(
          listenable: Listenable.merge([_keyboardHeight, _direction]),
          builder: (overlayContext, _) {
            final layout = _calculateDropdownLayout(
              overlayContext: overlayContext,
              anchorSize: size,
              keyboardHeight: _keyboardHeight.value,
            );

            return CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor:
                  layout.showAbove ? Alignment.topLeft : Alignment.bottomLeft,
              followerAnchor:
                  layout.showAbove ? Alignment.bottomLeft : Alignment.topLeft,
              offset: layout.offset,
              child: Align(
                alignment: layout.showAbove
                    ? AlignmentDirectional.bottomStart
                    : AlignmentDirectional.topStart,
                child: SizedBox(
                  width: layout.width,
                  child: _buildDropdownContainer(maxHeight: layout.maxHeight),
                ),
              ),
            );
          },
        );
      },
      child: (_) => CompositedTransformTarget(
        link: _layerLink,
        child: _buildSearchField(),
      ),
    );
  }

  Widget _buildDropdownContainer({required double maxHeight}) {
    if (widget.hideOnEmpty &&
        _results.isEmpty &&
        !_isLoading &&
        _error == null) {
      return const SizedBox.shrink();
    }

    final decorationBuilder = widget.decorationBuilder ??
        (context, child) => Card(
              clipBehavior: Clip.hardEdge,
              margin: EdgeInsets.zero,
              child: child,
            );

    return MouseRegion(
      onEnter: (_) => _isMouseOverDropdown = true,
      onExit: (_) {
        _isMouseOverDropdown = false;
        if (!focusNode.hasFocus && widget.hideOnUnfocus) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !focusNode.hasFocus && !_isMouseOverDropdown) {
              _hideOverlay();
            }
          });
        }
      },
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: decorationBuilder(
          context,
          ConstrainedBox(
            constraints: widget.dropdownConstraints.copyWith(
              maxHeight: maxHeight,
            ),
            child: _buildDropdownContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    if (widget.builder != null) {
      return widget.builder!(context, controller, focusNode);
    }

    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final decoration = widget.inputDecoration ??
            InputDecoration(
              isDense: true,
              filled: true,
              hintText: widget.hintText,
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
            );

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          decoration: decoration.copyWith(
            hintText: decoration.hintText ?? widget.hintText,
            suffixIcon: value.text.isNotEmpty
                ? (decoration.suffixIcon ??
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.clear();
                      },
                    ))
                : decoration.suffixIcon,
          ),
        );
      },
    );
  }
}

/// Computed geometry layout for the suggestions dropdown overlay.
class _DropdownLayout {
  final bool showAbove;
  final double width;
  final double maxHeight;
  final Offset offset;

  const _DropdownLayout({
    required this.showAbove,
    required this.width,
    required this.maxHeight,
    required this.offset,
  });
}

/// A controller to manually open, close, or toggle the suggestions dropdown overlay.
class SuggestionsController<T> {
  _PaginatedTypeAheadState<T>? _state;

  void _attach(_PaginatedTypeAheadState<T> state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Whether the suggestions dropdown is currently open.
  bool get isOpen => _state?._overlayController.isShowing ?? false;

  /// Manually opens the suggestions dropdown overlay.
  ///
  /// If there are no results yet for the current query, it will trigger a search.
  void open() {
    if (_state == null) return;
    final needsSearch = _state!._results.isEmpty && !_state!._isLoading;
    if (_state!._currentQuery != _state!.controller.text || needsSearch) {
      _state!._search(_state!.controller.text);
    } else {
      _state!._showOverlay();
    }
  }

  /// Manually closes the suggestions dropdown overlay.
  void close() {
    _state?.focusNode.unfocus();
    _state?._hideOverlay();
  }

  /// Manually selects an item, unfocuses the text field, and closes the suggestions dropdown.
  void select(T item) {
    _state?._onItemSelected(item);
  }

  /// Toggles the visibility of the suggestions dropdown overlay.
  void toggle() {
    if (isOpen) {
      close();
    } else {
      open();
    }
  }
}