import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iscte_spots/helper/constants.dart';
import 'package:iscte_spots/services/auth/auth_storage_service.dart';
import 'package:iscte_spots/services/leaderboard/leaderboard_service.dart';
import 'package:iscte_spots/services/logging/LoggerService.dart';
import 'package:iscte_spots/widgets/network/error.dart';
import 'package:iscte_spots/widgets/util/iscte_theme.dart';

//const API_ADDRESS = "http://192.168.1.124";

//const API_ADDRESS_PROD = "https://194.210.120.48";
//const API_ADDRESS_TEST = "http://192.168.1.124";
//const API_ADDRESS_TEST_LATEST_USED = "http://192.168.1.66";

const FlutterSecureStorage secureStorage = FlutterSecureStorage();

// FOR ISOLATED TESTING
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeaderBoardPage());
}

class LeaderBoardPage extends StatefulWidget {
  static const pageRoute = "/leaderboard";
  static const IconData icon = Icons.leaderboard;

  const LeaderBoardPage({
    Key? key,
    this.hasAppBar = true,
  }) : super(key: key);

  final bool hasAppBar;

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  late Map<String, dynamic> affiliationMap;

  Future<String> loadAffiliationData() async {
    var jsonText =
        await rootBundle.loadString('Resources/Affiliations/affiliations.json');
    setState(
        () => affiliationMap = json.decode(utf8.decode(jsonText.codeUnits)));
    return 'success';
  }

  static const List<Widget> _pages = <Widget>[
    GlobalLeaderboard(),
    AffiliationLeaderboard(),
    RelativeLeaderboard(),
  ];

  //Page Selection Mechanics
  void _onItemTapped(int index) {
    setState(() {
      _tabController.animateTo(index);
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadAffiliationData();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: !widget.hasAppBar
          ? null
          : AppBar(
              title: Text(
                AppLocalizations.of(context)!.leaderboardPageTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: IscteTheme.iscteColor),
              ), //AppLocalizations.of(context)!.quizPageTitle)
            ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll) {
          overscroll.disallowIndicator();
          return true;
        },
        child: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: _pages,
        ), // _pages[_selectedIndex],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: IscteTheme.appbarRadius,
          topRight: IscteTheme.appbarRadius,
        ),
        child: BottomNavigationBar(
          //type: BottomNavigationBarType.shifting,
          type: BottomNavigationBarType.shifting,
          backgroundColor: Theme.of(context).primaryColor,
          selectedItemColor: IscteTheme.iscteColor,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          elevation: 8,
          enableFeedback: true,
          iconSize: 30,
          selectedFontSize: 13,
          unselectedFontSize: 10,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          //selectedItemColor: Colors.amber[800],
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.globe),
              backgroundColor: Theme.of(context).primaryColor,
              label: AppLocalizations.of(context)!.leaderboardGlobal,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.group),
              backgroundColor: Theme.of(context).primaryColor,
              label: AppLocalizations.of(context)!.leaderboardAffiliation,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_on),
              backgroundColor: Theme.of(context).primaryColor,
              label: AppLocalizations.of(context)!.leaderboardNearMe,
            ),
          ],
        ),
      ),
    );
  }
}

class AffiliationLeaderboard extends StatefulWidget {
  const AffiliationLeaderboard({Key? key}) : super(key: key);

  @override
  AffiliationLeaderboardState createState() => AffiliationLeaderboardState();
}

class AffiliationLeaderboardState extends State<AffiliationLeaderboard>
    with AutomaticKeepAliveClientMixin {
  String selectedType = "-";
  String selectedAffiliation = "-";
  bool firstSearch = false;
  bool canSearch = false;

  Map<String, dynamic> affiliationMap = {
    "-": ["-"]
  };
  bool readJson = false;

  Future<List<dynamic>> fetchLeaderboard(BuildContext context) async {
    try {
      String apiToken = await LoginStorageService.getBackendApiKey();

      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      final request = await client.getUrl(Uri.parse(
          '${BackEndConstants.API_ADDRESS}/api/users/leaderboard?type=$selectedType&affiliation=$selectedAffiliation'));
      request.headers.add("Authorization", "Token $apiToken");
      final response = await request.close();
      var json = jsonDecode(await response.transform(utf8.decoder).join());

      LoggerService.instance.debug(json);
      if (response.statusCode == 200) {
        return json;
      }
    } catch (e) {
      LoggerService.instance.error(e);
      rethrow;
    }
    throw Exception('Failed to load leaderboard');
  }

  Future<String> loadAffiliationDataFromFile() async {
    var jsonText =
        await rootBundle.loadString('Resources/Affiliations/affiliations.json');
    readJson = true;
    setState(
        () => affiliationMap = json.decode(utf8.decode(jsonText.codeUnits)));
    return 'success';
  }

  Future<String> fetchAffiliationData() async {
    try {
      String? apiToken = await secureStorage.read(key: "backend_api_key");

      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      final request = await client.getUrl(
          Uri.parse('${BackEndConstants.API_ADDRESS}/api/users/affiliations'));
      request.headers.add("Authorization", "Token $apiToken");
      final response = await request.close();

      if (response.statusCode == 200) {
        affiliationMap =
            jsonDecode(await response.transform(utf8.decoder).join());
        setState(() {});
        return "success";
      }
    } catch (e) {
      LoggerService.instance.debug(e);
    }
    return "fail";
  }

  @override
  void initState() {
    super.initState();
    fetchAffiliationData();
    //loadAffiliationDataFromFile();
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SizedBox(
          // Container to hold the description
          height: 50,
          child: Center(
            child: Text(
                AppLocalizations.of(context)!.leaderboardAffiliationTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 15),
            Flexible(
              flex: 1,
              child: Column(
                children: [
                  Text(AppLocalizations.of(context)!.leaderboardAffiliation),
                  DropdownButton(
                    isExpanded: true,
                    value: selectedType,
                    items: (affiliationMap.keys.toList())
                        .map(
                          (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                  type == "*"
                                      ? AppLocalizations.of(context)!
                                          .leaderboardAffiliationAllDropdown
                                      : type == "-"
                                          ? AppLocalizations.of(context)!
                                              .leaderboardAffiliationNoneDropdown
                                          : type,
                                  style: const TextStyle(fontSize: 13))),
                        )
                        .toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return affiliationMap.keys.toList().map((type) {
                        return Center(
                          child: SizedBox(
                              width: double.maxFinite,
                              child: Text(
                                  type == "*"
                                      ? AppLocalizations.of(context)!
                                          .leaderboardAffiliationAllDropdown
                                      : type == "-"
                                          ? AppLocalizations.of(context)!
                                              .leaderboardAffiliationNoneDropdown
                                          : type,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13))),
                        );
                      }).toList();
                    },
                    onChanged: (String? newValue) {
                      setState(() {
                        canSearch = false;
                        selectedType = newValue!;
                        selectedAffiliation = "-";
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Flexible(
              flex: 1,
              child: Column(
                children: [
                  Text(AppLocalizations.of(context)!
                      .leaderboardAffiliationDepartment),
                  DropdownButton(
                    isExpanded: true,
                    value: selectedAffiliation,
                    items: (affiliationMap[selectedType])
                        .map<DropdownMenuItem<String>>(
                          (aff) => DropdownMenuItem<String>(
                              value: aff,
                              child: Text(
                                  aff == "*"
                                      ? AppLocalizations.of(context)!
                                          .leaderboardDepartmentAllDropdown
                                      : aff == "-"
                                          ? AppLocalizations.of(context)!
                                              .leaderboardDepartmentNoneDropdown
                                          : aff,
                                  style: const TextStyle(fontSize: 13))),
                        )
                        .toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return (affiliationMap[selectedType] as List<dynamic>)
                          .map((aff) {
                        return Center(
                          child: Text(
                              aff == "*"
                                  ? AppLocalizations.of(context)!
                                      .leaderboardDepartmentAllDropdown
                                  : aff == "-"
                                      ? AppLocalizations.of(context)!
                                          .leaderboardDepartmentNoneDropdown
                                      : aff,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13)),
                        );
                      }).toList();
                    },
                    onChanged: (selectedType == "-")
                        ? null
                        : (String? newValue) {
                            if (newValue != "-") {
                              setState(() {
                                canSearch = true;
                                firstSearch = true;
                                selectedAffiliation = newValue!;
                              });
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
        if (canSearch)
          Expanded(
              child: LeaderboardList(
            key: UniqueKey(),
            fetchFunction: fetchLeaderboard,
            showRank: true,
          ))
        else if (!firstSearch && readJson)
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.leaderboardAffiliationSelect,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }
}

class GlobalLeaderboard extends StatelessWidget {
  const GlobalLeaderboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          // Container to hold the description
          height: 50,
          child: Center(
            child: Text(AppLocalizations.of(context)!.leaderboardGlobalTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        const Expanded(
          child: LeaderboardList(
            fetchFunction: LeaderboardService.fetchGlobalLeaderboard,
            showRank: true,
          ),
        ),
      ],
    );
  }
}

class RelativeLeaderboard extends StatelessWidget {
  const RelativeLeaderboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          // Container to hold the description
          height: 50,
          child: Center(
            child: Text(AppLocalizations.of(context)!.leaderboardNearMeTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        const Expanded(
            child: LeaderboardList(
          fetchFunction: LeaderboardService.fetchRelativeLeaderboard,
          showRank: false,
        )),
      ],
    );
  }
}

class LeaderboardList extends StatefulWidget {
  final Future<List<dynamic>> Function(BuildContext context) fetchFunction;
  final bool showRank;
  //Used to highlight the user in the "near me" leaderboard page

  const LeaderboardList({
    Key? key,
    required this.fetchFunction,
    required this.showRank,
  }) : super(key: key);

  @override
  LeaderboardListState createState() => LeaderboardListState();
}

class LeaderboardListState extends State<LeaderboardList> {
  late Future<List<dynamic>> futureLeaderboard;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    futureLeaderboard = widget.fetchFunction(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureLeaderboard,
      builder: (context, snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          var items = snapshot.data as List<dynamic>;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                if (!isLoading) {
                  futureLeaderboard = widget.fetchFunction(context);
                }
              });
            },
            child: items.isEmpty
                ? const Center(child: Text("Não foram encontrados resultados"))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      bool isMainUser = items[index]["is_user"] ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Card(
                          child: ListTile(
                            title: Text(items[index]["name"].toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: isMainUser
                                            ? IscteTheme.iscteColor
                                            : null)),
                            subtitle: Text(
                              "${AppLocalizations.of(context)!.leaderboardPoints}: ${items[index]["points"]} "
                              "\n${AppLocalizations.of(context)!.leaderboardAffiliation}: ${items[index]["affiliation_name"]}",
                            ),
                            minVerticalPadding: 10.0,
                            trailing: widget.showRank
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                        if (index == 0)
                                          Image.asset(
                                              "Resources/Img/LeaderBoardIcons/gold_medal.png")
                                        else if (index == 1)
                                          Image.asset(
                                              "Resources/Img/LeaderBoardIcons/silver_medal.png")
                                        else if (index == 2)
                                          Image.asset(
                                              "Resources/Img/LeaderBoardIcons/bronze_medal.png"),
                                        const SizedBox(width: 10),
                                        Text("#${index + 1}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20)),
                                      ])
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          );
        } else if (snapshot.connectionState != ConnectionState.done) {
          children = const <Widget>[
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator.adaptive(),
            ),
          ];
        } else if (snapshot.hasError) {
          children = [DynamicErrorWidget.networkError(context: context)];
        } else {
          children = const <Widget>[
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator.adaptive(),
            ),
          ];
        }
        return GestureDetector(
          onTap: () {
            setState(() {
              if (!isLoading) {
                futureLeaderboard = widget.fetchFunction(context);
              }
            });
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
