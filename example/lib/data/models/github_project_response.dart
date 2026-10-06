import 'package:json_annotation/json_annotation.dart';

part 'github_project_response.g.dart';

@JsonSerializable()
class GithubProjectResponse {
  @JsonKey(name: 'total_count')
  final int? totalCount;

  @JsonKey(name: 'incomplete_results')
  final bool? incompleteResults;

  final List<GithubRepository>? items;

  const GithubProjectResponse({
    this.totalCount,
    this.incompleteResults,
    this.items,
  });

  factory GithubProjectResponse.fromJson(Map<String, dynamic> json) =>
      _$GithubProjectResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GithubProjectResponseToJson(this);
}

@JsonSerializable()
class GithubRepository {
  final int? id;
  final String? name;

  @JsonKey(name: 'full_name')
  final String? fullName;

  final String? description;

  @JsonKey(name: 'html_url')
  final String? htmlUrl;

  @JsonKey(name: 'stargazers_count')
  final int? stargazersCount;

  final String? language;

  final GithubOwner? owner;

  const GithubRepository({
    this.id,
    this.name,
    this.fullName,
    this.description,
    this.htmlUrl,
    this.stargazersCount,
    this.language,
    this.owner,
  });

  factory GithubRepository.fromJson(Map<String, dynamic> json) =>
      _$GithubRepositoryFromJson(json);

  Map<String, dynamic> toJson() => _$GithubRepositoryToJson(this);
}

@JsonSerializable()
class GithubOwner {
  final String? login;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  const GithubOwner({
    this.login,
    this.avatarUrl,
  });

  factory GithubOwner.fromJson(Map<String, dynamic> json) =>
      _$GithubOwnerFromJson(json);

  Map<String, dynamic> toJson() => _$GithubOwnerToJson(this);
}
