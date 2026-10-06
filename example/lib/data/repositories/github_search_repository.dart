import '../models/github_project_response.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';

class GithubSearchRepository {
  final ApiClient _apiClient;

  GithubSearchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(DioClient.instance);

  /// Fetches a paginated page of GitHub repositories matching [query].
  ///
  /// Returns a record of `(items, hasMore)`.
  Future<(List<GithubRepository>?, bool)> searchRepositories({
    required String query,
    required int page,
    int perPage = 10,
    String sort = 'stars',
    String order = 'desc',
  }) async {
    final searchQuery = query.trim().isEmpty
        ? 'language:dart'
        : '$query language:dart';

    final response = await _apiClient.fetchRepositories(
      searchQuery,
      sort,
      order,
      perPage,
      page,
    );

    final totalCount = response.totalCount ?? 0;
    final hasMore = page * perPage < totalCount;

    return (response.items, hasMore);
  }
}
