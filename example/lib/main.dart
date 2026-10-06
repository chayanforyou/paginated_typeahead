import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:paginated_typeahead/paginated_typeahead.dart';

import 'data/models/github_project_response.dart';
import 'data/repositories/github_search_repository.dart';
import 'frame.dart';
import 'options.dart';
import 'settings.dart';
import 'widgets/app_search_field.dart';
import 'widgets/repo_details_view.dart';
import 'widgets/repo_suggestion_tile.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialFrame(
      exampleBuilder: (context, controller, settings) =>
          ExampleTypeAhead(controller: controller, settings: settings),
      settingsBuilder: (context, controller, settings) =>
          SettingsTypeAhead(controller: controller, settings: settings),
    );
  }
}

class ExampleTypeAhead extends StatefulWidget {
  const ExampleTypeAhead({
    super.key,
    required this.controller,
    required this.settings,
  });

  final TextEditingController controller;
  final FieldSettings settings;

  @override
  State<ExampleTypeAhead> createState() => _ExampleTypeAheadState();
}

class _ExampleTypeAheadState extends State<ExampleTypeAhead> {
  final GithubSearchRepository _repository = GithubSearchRepository();

  GithubRepository? _selectedRepo;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final isUp = settings.direction.value == VerticalDirection.up;

    final children = [
      PaginatedTypeAhead<GithubRepository>(
        initialPage: 1,
        controller: widget.controller,
        builder: (context, ctrl, focus) => AppSearchField(
          controller: ctrl,
          focusNode: focus,
          hintText: 'Search repositories...',
        ),
        debounceDuration: settings.debounce.value
            ? const Duration(milliseconds: 300)
            : Duration.zero,
        hideOnSelect: settings.hideOnSelect.value,
        clearOnSelect: settings.clearOnSelect.value,
        hideOnUnfocus: settings.hideOnUnfocus.value,
        constrainWidth: settings.constrainWidth.value,
        direction: settings.direction.value,
        suggestionsCallback: (query, page) =>
            _repository.searchRepositories(query: query, page: page),
        onSelected: (repo) {
          setState(() => _selectedRepo = repo);
        },
        separatorBuilder: settings.dividers.value
            ? (context, index) => const Divider(height: 1)
            : null,
        itemBuilder: (repo) => RepoSuggestionTile(repo: repo),
        loadingBuilder: (context) => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        loadMoreLoadingBuilder: (context) => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
        emptyBuilder: (context) => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No repositories found')),
        ),
        errorBuilder: (context, error) => Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 56,
                ),
                const SizedBox(height: 8),
                Text(
                  _getErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ),
        loadMoreErrorBuilder: (context, retry) => Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry loading more'),
            ),
          ),
        ),
      ),
      const SizedBox(height: 32),
      Expanded(child: RepoDetailsView(repo: _selectedRepo)),
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUp ? children.reversed.toList() : children,
      ),
    );
  }

  String _getErrorMessage(Object? error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Network error occurred';
    }
    return error?.toString() ?? 'Failed to load repositories';
  }
}
