import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:iscte_spots/models/timeline/feedback_form_result.dart';
import 'package:iscte_spots/pages/timeline/state/timeline_state.dart';
import 'package:iscte_spots/services/timeline/feedback_service.dart';
import 'package:iscte_spots/widgets/dynamic_widgets/dynamic_icon_button.dart';
import 'package:iscte_spots/widgets/dynamic_widgets/dynamic_loading_widget.dart';
import 'package:iscte_spots/widgets/dynamic_widgets/dynamic_snackbar.dart';
import 'package:iscte_spots/widgets/dynamic_widgets/dynamic_text_button.dart';
import 'package:iscte_spots/widgets/util/iscte_theme.dart';

class FeedbackFormButon extends StatelessWidget {
  const FeedbackFormButon({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Future<List<int>>>(
      valueListenable: TimelineState.yearsList,
      builder: (context, currentYearsListValue, child) =>
          FutureBuilder<List<int>>(
              future: currentYearsListValue,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    if (snapshot.hasData) {
                      return DynamicIconButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => FeedbackForm(
                            yearsList: snapshot.data!,
                            selectedYear: TimelineState.selectedYear.value,
                          ),
                        ),
                        child: const Icon(
                          //Icons.feedback_outlined,
                          CupertinoIcons.exclamationmark_bubble,
                          color: IscteTheme.iscteColor,
                        ),
                      );
                    } else {
                      return const DynamicLoadingWidget();
                    }
                  default:
                    return const DynamicLoadingWidget();
                }
              }),
    );
  }
}

class FeedbackForm extends StatefulWidget {
  FeedbackForm({Key? key, required this.yearsList, this.selectedYear})
      : super(key: key);
  final int? selectedYear;
  List<int> yearsList;

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  int? selectedYearState;
  late List<int> yearsList;
  late List<DropdownMenuItem<int>> list;

  final GlobalKey<FormState> _feedbackFormKey = GlobalKey<FormState>();
  TextEditingController descriptionFieldController = TextEditingController();
  TextEditingController nameFieldController = TextEditingController();
  TextEditingController emailFieldController = TextEditingController();

  AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction;

  @override
  void initState() {
    yearsList = List.from(widget.yearsList); //copies initial List
    selectedYearState = widget.selectedYear;
    if (!yearsList.contains(-1)) {
      yearsList.insert(0, -1);
    }
    list = yearsList
        .map<DropdownMenuItem<int>>(
          (int e) => DropdownMenuItem(
            value: e,
            child: Builder(builder: (context) {
              return Text(e != -1
                  ? e.toString()
                  : AppLocalizations.of(context)!
                      .feedbackFormGeneralFeedbackDropdownText);
            }),
          ),
        )
        .toList(growable: false);
    setState(() {});
    super.initState();
  }

  void submitForm() async {
    if (_feedbackFormKey.currentState?.validate() ?? false) {
      final feedbackresult = FeedbackFormResult(
          email: emailFieldController.text,
          name: nameFieldController.text,
          description: descriptionFieldController.text,
          year: selectedYearState == -1 ? null : selectedYearState!);
      bool sendFeedbackSuccess = await FeedbackService.sendFeedback(
          feedbackFormResult: feedbackresult);

      if (!mounted) return;
      Navigator.of(context).pop();
      DynamicSnackBar.showSnackBar(
        context,
        sendFeedbackSuccess
            ? Text(
                AppLocalizations.of(context)!.feedbackFormSubmissionSuccess,
                style: const TextStyle(color: IscteTheme.iscteColor),
              )
            : Text(
                AppLocalizations.of(context)!.feedbackFormSubmissionError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
        const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var base = Theme.of(context).textTheme.titleLarge;
    var textstyle = base?.copyWith(color: IscteTheme.iscteColor);
    const SizedBox formSpacer = SizedBox(height: 16.0);

    return AlertDialog(
      contentTextStyle: textstyle,
      title: Text(AppLocalizations.of(context)!.feedbackFormTitle),
      actions: [
        DynamicTextButton(
          onPressed: submitForm,
          style: ButtonStyle(
              foregroundColor:
                  MaterialStateProperty.all(IscteTheme.iscteColor)),
          child: Text(
            AppLocalizations.of(context)!.feedbackFormSubmit,
            style: textstyle,
          ),
        ),
        DynamicTextButton(
          onPressed: Navigator.of(context).pop,
          style: ButtonStyle(
              foregroundColor:
                  MaterialStateProperty.all(IscteTheme.iscteColor)),
          child: Text(
            AppLocalizations.of(context)!.feedbackFormCancel,
            style: base,
          ),
        )
      ],
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: SingleChildScrollView(
          child: Form(
              key: _feedbackFormKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    textAlignVertical: TextAlignVertical.top,
                    textAlign: TextAlign.start,
                    autofocus: true,
                    style: base,
                    autovalidateMode: autovalidateMode,
                    controller: nameFieldController,
                    textInputAction: TextInputAction.next,
                    cursorColor: IscteTheme.iscteColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            ?.feedbackFormValidation;
                      } else {
                        return null;
                      }
                    },
                    decoration: InputDecoration(
                        labelStyle: textstyle,
                        labelText: AppLocalizations.of(context)
                            ?.feedbackFormNameField),
                  ),
                  formSpacer,
                  TextFormField(
                    textAlignVertical: TextAlignVertical.top,
                    textAlign: TextAlign.start,
                    style: base,
                    autovalidateMode: autovalidateMode,
                    cursorColor: IscteTheme.iscteColor,
                    textInputAction: TextInputAction.next,
                    controller: emailFieldController,
                    decoration: InputDecoration(
                        labelStyle: textstyle,
                        labelText: AppLocalizations.of(context)
                            ?.feedbackFormEmailField),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            ?.feedbackFormValidation;
                        //} else if (!RegExp(r"\S+[@]\S+\.\S+").hasMatch(value)) {
                        //https://regex101.com/r/TZDJmb/1
                      } else if (!RegExp(
                              r"(([_A-Za-z0-9-]+)(\.[_A-Za-z0-9-]+)*|[\[\{\(]([_A-Za-z0-9-,;\/\|\s?]+)(\.[_A-Za-z0-9-,;\/\|\s?]+)*[\}\]\)])\s*@\s*[_A-Za-z0-9-]+(\.[_A-Za-z0-9-]+)*(\.[A-Za-z]{2,})")
                          .hasMatch(value)) {
                        //RegExp Explanation (checks for @ followed by any number of non whitespace character followed by a dot "." and then followed by any number of non whitespace characters)
                        //https://regex101.com/r/pYrcfO/1
                        return AppLocalizations.of(context)
                            ?.feedbackFormEmailValidation;
                      }
                      return null;
                    },
                  ),
                  formSpacer,
                  DropdownButtonFormField<int>(
                    style: textstyle,
                    onSaved: (val) {},
                    value: selectedYearState,
                    autovalidateMode: autovalidateMode,
                    menuMaxHeight: MediaQuery.of(context).size.height * 0.5,
                    items: list,
                    onChanged: (value) {
                      if (selectedYearState != value) {
                        setState(() => selectedYearState = value);
                      }
                    },
                  ),
                  formSpacer,
                  TextFormField(
                    textAlignVertical: TextAlignVertical.top,
                    textAlign: TextAlign.start,
                    maxLines: 5,
                    style: base,
                    textInputAction: TextInputAction.newline,
                    autovalidateMode: autovalidateMode,
                    controller: descriptionFieldController,
                    cursorColor: IscteTheme.iscteColor,
                    decoration: InputDecoration(
                        labelStyle: textstyle,
                        labelText: AppLocalizations.of(context)
                            ?.feedbackFormDescriptionField),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)
                            ?.feedbackFormValidation;
                      } else {
                        return null;
                      }
                    },
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
