import 'dart:convert';
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:infomatterapp/models/models.dart';

class SourceApiClient {
  static const baseUrl = 'http://39.105.127.55:3001';
  final http.Client httpClient;

  SourceApiClient({@required this.httpClient}): assert(httpClient != null);

  Future<List<Source>> fetchSources(int lastCount, int lastId, int limit) async {
    final url = "$baseUrl/sources?last_count=$lastCount&last_id=$lastId&batch_size=$limit";
    print(url);
    final response = await httpClient.get(url,
        headers: {HttpHeaders.authorizationHeader: await getToken()});
    print("fetchSources: " + response.statusCode.toString() + ": " + response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((rawSource) {
        return Source(
            id: rawSource['id'],
            name: rawSource['name'],
            photo: rawSource['photo'],
            description: rawSource['description'],
            link: rawSource['link'],
            followerCount: rawSource['follower'],
            isFollowing: _isNumeric(rawSource['user_id'].toString()) ?? false
        );
      }).toList();
    } else {
      throw Exception('error fetching sources');
    }
  }

  Future<List<Source>> fetchSourcesOfCategory(String cate, int lastCount, int lastId, int limit) async {
    final response = await httpClient.get("$baseUrl/sources?category=$cate&last_count=$lastCount&last_id=$lastId&batch_size=$limit",
        headers: {HttpHeaders.authorizationHeader: await getToken()});
    print("fetchSources: " + response.statusCode.toString() + ": " + response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((rawSource) {
        return Source(
            id: rawSource['id'],
            name: rawSource['name'],
            photo: rawSource['photo'],
            description: rawSource['description'],
            link: rawSource['link'],
            followerCount: rawSource['follower'],
            isFollowing: _isNumeric(rawSource['user_id'].toString()) ?? false
        );
      }).toList();
    } else {
      throw Exception('error fetching sources of category');
    }
  }

  Future<bool> requestFollow(int sourceId) async{
    final response = await httpClient.get("$baseUrl/users/follow?source_id=$sourceId",
        headers: {HttpHeaders.authorizationHeader: await getToken()});
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('follow failed');
      return false;
    }
  }

  Future<bool> requestUnfollow(int sourceId) async{
    final response = await httpClient.get("$baseUrl/users/unfollow?source_id=$sourceId",
        headers: {HttpHeaders.authorizationHeader: await getToken()});
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('follow failed');
      return false;
    }
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String token =  prefs.getString("token");
    return token;
  }

  bool _isNumeric(String str) {
    if(str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }
}