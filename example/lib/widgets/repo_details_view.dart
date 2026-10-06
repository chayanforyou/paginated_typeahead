import 'package:flutter/material.dart';

import '../data/models/github_project_response.dart';

class RepoDetailsView extends StatelessWidget {
  const RepoDetailsView({
    super.key,
    required this.repo,
  });

  final GithubRepository? repo;

  @override
  Widget build(BuildContext context) {
    if (repo == null) {
      return const _EmptyPlaceholder();
    }
    return _RepoCard(repo: repo!);
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({required this.repo});

  final GithubRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              children: [
                if (repo.owner?.avatarUrl != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(repo.owner!.avatarUrl!),
                    radius: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo.fullName ?? repo.name ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (repo.htmlUrl != null)
                        Text(
                          repo.htmlUrl!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (repo.description != null) ...[
              Text(
                repo.description!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${repo.stargazersCount ?? 0} stars'),
                const SizedBox(width: 16),
                if (repo.language != null) ...[
                  const Icon(Icons.code, size: 18),
                  const SizedBox(width: 4),
                  Text(repo.language!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Flutter Repositories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Type in the search field above to explore GitHub repositories',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
