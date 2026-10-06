import 'package:flutter/material.dart';

import '../data/models/github_project_response.dart';

class RepoSuggestionTile extends StatelessWidget {
  const RepoSuggestionTile({
    super.key,
    required this.repo,
  });

  final GithubRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        repo.name ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: repo.description != null
          ? Text(
              repo.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (repo.language != null) ...[
            Text(
              repo.language!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text('${repo.stargazersCount ?? 0}'),
        ],
      ),
    );
  }
}
