import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Settings settings = Settings.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: AnimatedBuilder(
            animation: settings,
            builder: (context, widget) => SettingsList(
                  sections: [
                    SettingsSection(
                      title: const Text('Lichess'),
                      tiles: [
                        SettingsTile(
                          title: const Text('API access token'),
                          value: Text(
                              settings.getString(Settings.lichessApiKey) ??
                                  'Not set'),
                          onPressed: openLichessApiKeyPopup,
                        )
                      ],
                    )
                  ],
                )));
  }

  Future<void> openLichessApiKeyPopup(BuildContext context) async {
    final Uri lichessOauthUrl = Uri.parse(
        'https://lichess.org/account/oauth/token/create?scopes[]=challenge:write&scopes[]=board:play&description=RoboChess');
    GlobalKey<FormState> formKey = GlobalKey();

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Lichess API access token'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                      softWrap: true,
                      text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(
                                text:
                                    'To give this app access to the Lichess API, please open '),
                            TextSpan(
                                text: lichessOauthUrl.toString(),
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(lichessOauthUrl,
                                        mode: LaunchMode.externalApplication);
                                  }),
                            const TextSpan(
                                text:
                                    ', create an API access token and copy it into the field below.'),
                          ])),
                  const Divider(),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      initialValue: settings.getString(Settings.lichessApiKey),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (String? result) {
                        if (result != null) {
                          settings.setString(Settings.lichessApiKey, result);
                        }
                      },
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                    onPressed: () {
                      formKey.currentState!.save();
                      Navigator.pop(context);
                    },
                    child: const Text('OK')),
              ],
            ));
  }
}
