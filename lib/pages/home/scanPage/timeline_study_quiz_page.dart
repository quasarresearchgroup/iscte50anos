import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:iscte_spots/models/requests/spot_info_request.dart';
import 'package:iscte_spots/models/timeline/event.dart';
import 'package:iscte_spots/models/timeline/timeline_filter_params.dart';
import 'package:iscte_spots/pages/quiz/quiz_list_menu.dart';
import 'package:iscte_spots/pages/timeline/details/timeline_details_page.dart';
import 'package:iscte_spots/pages/timeline/timeline_body.dart';
import 'package:iscte_spots/services/logging/LoggerService.dart';
import 'package:iscte_spots/services/timeline/timeline_topic_service.dart';
import 'package:iscte_spots/widgets/dynamic_widgets/dynamic_alert_dialog.dart';
import 'package:iscte_spots/widgets/dynamic_widgets/dynamic_text_button.dart';
import 'package:iscte_spots/widgets/my_app_bar.dart';
import 'package:iscte_spots/widgets/util/iscte_theme.dart';

class TimelineStudyForQuiz extends StatelessWidget {
  static const String pageRoute = "QRScanResults";

  TimelineStudyForQuiz({
    Key? key,
    required SpotInfoRequest spotInfoRequest,
  })  : navigateBack = false,
        yearNotifier = ValueNotifier<int?>(null),
        super(key: key) {
    int spotID = spotInfoRequest.id;
    topicString = spotInfoRequest.title;
    originalEventsListFuture =
        TimelineTopicService.fetchEvents(topicIds: [spotID]);
    eventsListFutureNotifier = ValueNotifier(originalEventsListFuture);
    yearsListFutureNotifier = ValueNotifier(eventsListFutureNotifier.value.then(
        (List<Event> value) =>
            value.fold<Set<int>>({}, (previousValue, Event element) {
              previousValue.add(element.dateTime.year);
              return previousValue;
            }).toList()));
    yearsListFutureNotifier.value.then((value) {
      LoggerService.instance.debug(value);
      changeYearCallback(value.last);
    });
    topicNames = [spotInfoRequest.title];
  }

  TimelineStudyForQuiz.fromFilter(
      {Key? key, required TimelineFilterParams filterParams})
      : navigateBack = true,
        yearNotifier = ValueNotifier<int?>(null),
        super(key: key) {
    originalEventsListFuture = TimelineTopicService.fetchEvents(
        topicIds: filterParams.topics.map((e) => e.id));
    eventsListFutureNotifier = ValueNotifier(originalEventsListFuture);
    yearsListFutureNotifier = ValueNotifier(eventsListFutureNotifier.value.then(
        (List<Event> value) =>
            value.fold<Set<int>>({}, (previousValue, Event element) {
              previousValue.add(element.dateTime.year);
              return previousValue;
            }).toList()));

    topicString = filterParams.topics.map((e) => e.title).join("; ");
    topicNames = filterParams.topics
        .where((e) => e.title != null)
        .map((e) => e.title ?? "")
        .toSet();
  }

  final bool navigateBack;
  late final String topicString;
  late final Iterable<String> topicNames;
  late final Future<List<Event>> originalEventsListFuture;
  late final ValueNotifier<Future<List<Event>>> eventsListFutureNotifier;
  late final ValueNotifier<Future<List<int>>> yearsListFutureNotifier;
  final ValueNotifier<int?> yearNotifier;
  final ScrollController topicScrollController = ScrollController();

  Future<void> changeYearCallback(int year) async {
    List<Event> originalEventsList = await originalEventsListFuture;
    eventsListFutureNotifier.value = Future<List<Event>>.value(
        originalEventsList
            .where((element) => element.dateTime.year == year)
            .toList());
    //List<int> yearsList = await yearsListFutureNotifier.value;
    yearNotifier.value = year;
    LoggerService.instance.debug(yearNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: AppLocalizations.of(context)!.qrScanResultScreen),
      bottomSheet: BottomSheet(
        elevation: 0,
        backgroundColor: Colors.transparent.withOpacity(0),
        enableDrag: false,
        onClosing: () {},
        builder: (context) {
          return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Scrollbar(
                  controller: topicScrollController,
                  thumbVisibility: true,
                  interactive: false,
                  child: SingleChildScrollView(
                    controller: topicScrollController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Row(
                      children: topicNames
                          .map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Chip(
                                  label: Text(
                                    e,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            color: IscteTheme.iscteColor),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                DynamicTextButton(
                  style: const ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(IscteTheme.iscteColor)),
                  child: Text(
                    AppLocalizations.of(context)!
                        .qrScanResultReadyForQuizButton,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  onPressed: () => DynamicAlertDialog.showDynamicDialog(
                      context: context,
                      icon: Icon(Icons.menu_book,
                          size: DynamicAlertDialog.iconSize),
                      title: Text(AppLocalizations.of(context)!
                          .qrScanResultReadyForQuizButtonDialogTitle),
                      content: Text(AppLocalizations.of(context)!
                          .qrScanResultReadyForQuizButtonDialogContent),
                      actions: [
                        DynamicTextButton(
                          onPressed: Navigator.of(context).pop,
                          child: Text(
                            AppLocalizations.of(context)!
                                .qrScanResultReadyForQuizButtonDialogCancelButton,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: IscteTheme.iscteColor),
                          ),
                        ),
                        DynamicTextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (navigateBack) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context)
                                  .pushReplacementNamed(QuizMenu.pageRoute);
                            }
                          },
                          style: const ButtonStyle(
                            backgroundColor:
                                MaterialStatePropertyAll(IscteTheme.iscteColor),
                            foregroundColor:
                                MaterialStatePropertyAll(Colors.white),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .qrScanResultReadyForQuizButtonDialogContinueButton,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        )
                      ]),
                ),
              ],
            ),
          );
        },
      ),
      body: ValueListenableBuilder<Future<List<int>>>(
        valueListenable: yearsListFutureNotifier,
        builder: (context, yearsListFuture, _) {
          return ValueListenableBuilder<Future<List<Event>>>(
            valueListenable: eventsListFutureNotifier,
            builder: (context, eventsListFuture, _) {
              return TimelineBody(
                isFilterTimeline: false,
                eventsListFuture: eventsListFuture,
                yearsListFuture: yearsListFuture,
                handleEventSelection: (eventId, context) =>
                    Navigator.of(context).pushNamed(
                        TimeLineDetailsPage.pageRoute,
                        arguments: eventId),
                changeYearCallback: changeYearCallback,
                currentYearNotifier: yearNotifier,
              );
            },
          );
        },
      ),
    );
  }
}
