import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

@JsonSerializable()
class AppConfig {
  final String appName;
  final String url;
  final String iconPath;

  AppConfig({required this.appName, required this.url, required this.iconPath});

  factory AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}
