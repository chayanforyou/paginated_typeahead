// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_project_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GithubProjectResponse _$GithubProjectResponseFromJson(
  Map<String, dynamic> json,
) => GithubProjectResponse(
  totalCount: (json['total_count'] as num?)?.toInt(),
  incompleteResults: json['incomplete_results'] as bool?,
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => GithubRepository.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GithubProjectResponseToJson(
  GithubProjectResponse instance,
) => <String, dynamic>{
  'total_count': instance.totalCount,
  'incomplete_results': instance.incompleteResults,
  'items': instance.items,
};

GithubRepository _$GithubRepositoryFromJson(Map<String, dynamic> json) =>
    GithubRepository(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      fullName: json['full_name'] as String?,
      description: json['description'] as String?,
      htmlUrl: json['html_url'] as String?,
      stargazersCount: (json['stargazers_count'] as num?)?.toInt(),
      language: json['language'] as String?,
      owner: json['owner'] == null
          ? null
          : GithubOwner.fromJson(json['owner'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GithubRepositoryToJson(GithubRepository instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'full_name': instance.fullName,
      'description': instance.description,
      'html_url': instance.htmlUrl,
      'stargazers_count': instance.stargazersCount,
      'language': instance.language,
      'owner': instance.owner,
    };

GithubOwner _$GithubOwnerFromJson(Map<String, dynamic> json) => GithubOwner(
  login: json['login'] as String?,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$GithubOwnerToJson(GithubOwner instance) =>
    <String, dynamic>{
      'login': instance.login,
      'avatar_url': instance.avatarUrl,
    };
