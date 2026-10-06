import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/github_project_response.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: "https://api.github.com")
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @GET("/search/repositories")
  Future<GithubProjectResponse> fetchRepositories(
    @Query("q") String query,
    @Query("sort") String sort,
    @Query("order") String order,
    @Query("per_page") int perPage,
    @Query("page") int page,
  );
}
