import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:iscte_spots/helper/constants.dart';
import 'package:iscte_spots/models/database/tables/database_page_table.dart';
import 'package:iscte_spots/models/requests/spot_info_request.dart';
import 'package:iscte_spots/models/requests/topic_request.dart';
import 'package:iscte_spots/models/timeline/content.dart';
import 'package:iscte_spots/models/visited_url.dart';
import 'package:iscte_spots/pages/home/scanPage/qr_scan_page.dart';
import 'package:iscte_spots/services/auth/exceptions.dart';
import 'package:iscte_spots/services/logging/LoggerService.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:synchronized/synchronized.dart';

import 'auth/auth_service.dart';
import 'auth/openday_login_service.dart';

class QRScanService {
  static Future<String> extractData(final String url) async {
    LoggerService.instance.debug("url:$url");
    try {
      final response = await http.Client().get(Uri.parse(url));
      //Status Code 200 means response has been received successfully
      if (response.statusCode == 200) {
        var lock = Lock();
        int millisecondsSinceEpoch2 = DateTime.now().millisecondsSinceEpoch;
        var title = parser
            .parse(response.body)
            .getElementsByClassName(QRScanPage.titleHtmlTag);
        String name = title.map((e) => e.text).join("");

        await DatabasePageTable.add(VisitedURL(
            content: name, dateTime: millisecondsSinceEpoch2, url: url));
        LoggerService.instance.debug(
            "-----------------title-----------------------\n$name\n$millisecondsSinceEpoch2");
        return name;
      } else {
        return 'ERROR: ${response.statusCode}.';
      }
    } on SocketException {
      rethrow;
    } catch (e) {
      LoggerService.instance.error(e);
      return 'ERROR: ${e.toString()}.';
    }
  }

  static Future<SpotInfoRequest> spotInfoRequest(
      {required BuildContext context, required Barcode barcode}) async {
    LoggerService.instance
        .debug("started request at ${DateTime.now()}\t${barcode.rawValue}");
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? apiToken =
        await secureStorage.read(key: AuthService.backendApiKeyStorageLocation);
    if (apiToken == null) {
      throw LoginException();
    }
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      final HttpClientRequest request;

      request = await client.getUrl(Uri.parse(
          '${BackEndConstants.API_ADDRESS}/api/spots/${barcode.rawValue}?app=true'));

      request.headers.add("Authorization", "Token $apiToken");

      final response = await request.close();
      if (response.statusCode == 403) {
        OpenDayLoginService.logOut(context);
        throw LoginException();
      } else if (response.statusCode == 404) {
        throw InvalidQRException();
      } else {
        var responseDecoded =
            jsonDecode(await response.transform(utf8.decoder).join());

        LoggerService.instance.debug(responseDecoded);

        if (responseDecoded["id"] != null && responseDecoded["title"] != null) {
          if ((responseDecoded["title"] as String).isNotEmpty) {
            return SpotInfoRequest(
              id: responseDecoded["id"],
              title: responseDecoded["title"],
            );
          } else {
            LoggerService.instance.debug("No title in spotInfoRequest");
          }
        }
        throw Exception("Bad response");
      }
    } on SocketException {
      LoggerService.instance.error("Socket Exception");
      rethrow;
    } catch (e) {
      LoggerService.instance.error("$e\n${barcode.rawValue}");
      rethrow;
    }
  }

  static Future<TopicRequest> topicRequest(
      {required BuildContext context, required int topicID}) async {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? apiToken =
        await secureStorage.read(key: AuthService.backendApiKeyStorageLocation);
    if (apiToken == null) {
      throw LoginException();
    }

    HttpClient client = HttpClient();
    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
    final HttpClientRequest request = await client.getUrl(
        Uri.parse('${BackEndConstants.API_ADDRESS}/api/topics/$topicID'));

    request.headers.add("Authorization", "Token $apiToken");

    final response = await request.close();

    if (response.statusCode == 403) {
      OpenDayLoginService.logOut(context);
      throw LoginException();
    } else if (response.statusCode == 404) {
      throw InvalidQRException();
    } else {
      var responseDecoded =
          jsonDecode(await response.transform(utf8.decoder).join());

      LoggerService.instance.debug(responseDecoded);
      try {
        if (responseDecoded["title"] != null &&
            responseDecoded["content"] != null) {
          var responseContentList = responseDecoded["content"];
          final List<Content> contentList = [];
          for (var content in responseContentList) {
            contentList.add(
              Content(
                description: content["title"],
                link: content["link"],
                type: contentTypefromString(content["type"]),
                id: 0,
              ),
            );
            throw UnimplementedError(); //TODO
          }
          return TopicRequest(
            title: responseDecoded["title"],
            contentList: contentList,
          );
        }
        throw Exception("Bad response");
      } on SocketException {
        LoggerService.instance.error("Socket Exception");
        rethrow;
      } catch (e) {
        LoggerService.instance.error(e);
        rethrow;
      }
    }
  }
}
