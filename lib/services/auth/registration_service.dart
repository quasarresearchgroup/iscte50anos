import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:iscte_spots/helper/constants.dart';
import 'package:iscte_spots/models/auth/registration_form_result.dart';
import 'package:iscte_spots/pages/auth/register/registration_error.dart';
import 'package:iscte_spots/services/auth/auth_storage_service.dart';
import 'package:iscte_spots/services/logging/LoggerService.dart';

class RegistrationService {
  static const String AfiliationsFile =
      'Resources/Affiliations/openday_affiliations.json';

  static Future<Map<String, dynamic>> getSchoolAffiliations() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      final String file = await rootBundle.loadString(AfiliationsFile);
      var jsonText = await rootBundle
          .loadString('Resources/Affiliations/openday_affiliations.json');
      Map<String, dynamic> affiliationMap =
          json.decode(utf8.decode(jsonText.codeUnits));
      return affiliationMap;
      /*final Map<String, List<String>> result = {};

      result["-"] = <String>["-"];
      file.split("\n").forEach((line) {
        List<String> lineSplit = line.split(",");
        String district = lineSplit[1];
        String school = lineSplit[0];
        if (result[district] == null) {
          result[district] = <String>["-", school];
        } else {
          result[district]!.add(school);
        }
      });
      return result;
        */
    } catch (e) {
      LoggerService.instance.error(e);
      rethrow;
    }
  }

  static Future<RegistrationError> registerNewUser(
      RegistrationFormResult registrationFormResult) async {
    try {
      LoggerService.instance
          .debug("registering new User:\n$registrationFormResult");

      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

      final HttpClientRequest request = await client.postUrl(
          Uri.parse('${BackEndConstants.API_ADDRESS}/api/auth/signup'));

      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(json.encode(registrationFormResult.toMap())));

      HttpClientResponse response = await request.close();
      LoggerService.instance.debug("response: $response");
      LoggerService.instance.debug("statusCode: ${response.statusCode}");
      var decodedResponse =
          await jsonDecode(await response.transform(utf8.decoder).join());
      LoggerService.instance.debug("response: $decodedResponse");

      RegistrationError responseRegistrationError;
      if (decodedResponse["code"] != null) {
        int responseErrorCode = decodedResponse["code"];
        responseRegistrationError =
            RegistrationErrorExtension.registrationErrorConstructor(
                responseErrorCode);
      } else {
        String responseApiToken = decodedResponse["api_token"];
        LoggerService.instance
            .debug("Created new user with token: $responseApiToken");

        LoginStorageService.storeLogInCredenials(
          username: registrationFormResult.username,
          password: registrationFormResult.password,
          apiKey: responseApiToken,
        );
        responseRegistrationError = RegistrationError.noError;
      }
      client.close();

      LoggerService.instance.debug(
          "response error code: $responseRegistrationError ; code: ${responseRegistrationError.code}");
      return responseRegistrationError;
    } catch (e) {
      LoggerService.instance.error(e);
      return RegistrationError.generalError;
    }
  }
}
