// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
      appName: json['appName'] as String,
      url: json['url'] as String,
      iconPath: json['iconPath'] as String,
    );

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
      'appName': instance.appName,
      'url': instance.url,
      'iconPath': instance.iconPath,
    };
