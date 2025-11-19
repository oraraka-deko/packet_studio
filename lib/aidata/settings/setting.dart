import 'dart:async';
// import 'dart:io'; // removed: not used in this file

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shortid/shortid.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/api_balance.dart';
import '../../utils/tool_func/tool.dart';
import '../../utils/telegram_reporter.dart';
import '../data/model/chat/config.dart';
import '../data/res/build_data.dart';
import '../data/res/github_id.dart';
import '../data/res/l10n.dart';
import '../data/res/openai.dart';
import '../data/res/url.dart';
import '../data/store/all.dart';
import '../generated/l10n/l10n.dart';
part 'mcp.dart';
part 'profile.dart';
part 'about.dart';
part 'def.dart';

class SettingsPage extends StatefulWidget {
  final SettingsPageArgs? args;

  const SettingsPage({super.key, this.args});

  static const route = AppRoute<SettingsPageRet, SettingsPageArgs>(
    page: SettingsPage.new,
    path: '/settings',
  );

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(
      length: SettingsTab.values.length,
      vsync: this,
      initialIndex: widget.args?.tabIndex.index ?? 0);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: UniqueKey(),
      appBar: CustomAppBar(
        title: Text(libL10n.setting),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: SettingsTab.tabs,
          dividerHeight: 0,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: SettingsTab.pages),
    );
  }
}

final class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

final class _AppSettingsPageState extends State<AppSettingsPage> {
  final _setStore = Stores.setting;
  final _autoDelTrashCtrl = TextEditingController();
  // UI constraints for this page
  static const double _maxElementWidth = 50.0;
  static const double _maxIconSize = 15.0;
  static const double _secondaryIconSize = 14.0;
  static const double _smallIconSize = 13.0;
  static const double _maxTextSize = 11.0;

  @override
  void dispose() {
    _autoDelTrashCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _autoDelTrashCtrl.text = _setStore.trashDays.get().toString();
  }

  @override
  Widget build(BuildContext context) {
    return MultiList(
      children: [
        [const CenterGreyTitle('App'), _buildApp()],
      ],
    );
  }

  Widget _buildApp() {
    final children = [
      _buildLocale(),
      // _buildColorSeed(),
      _buildThemeMode(),
      _buildUserName(),
        _buildGenTitle(),



      // _buildCheckUpdate(),
    ];
    return Column(children: children.map((e) => e.cardx).toList());
  }



  Widget _buildThemeMode() {
    return ValueListenableBuilder(
      valueListenable: _setStore.themeMode.listenable(),
      builder: (_, val, _) => ListTile(
        leading: Icon(Icons.sunny, size: _secondaryIconSize),
        title: Text(l10n.themeMode, style: TextStyle(fontSize: _maxTextSize)),
        onTap: () async {
          final result = await context.showPickSingleDialog(
            title: l10n.themeMode,
            items: ThemeMode.values,
            display: (e) => e.i18n,
            initial: ThemeMode.dark,
          );
          if (result != null) {
            _setStore.themeMode.set(1);
            context.pop();

            /// Set delay to true to wait for db update.
            RNodes.app.notify(delay: true);
          }
        },
        trailing: SizedBox(
          width: _maxElementWidth,
          child: Text(
            ThemeMode.values[val].name,
            style: UIs.text13Grey.copyWith(fontSize: _maxTextSize),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }



  Widget _buildLocale() {
    return ValueListenableBuilder(
      valueListenable: _setStore.locale.listenable(),
      builder: (_, val, _) => ListTile(
        leading: Icon(MingCute.translate_2_line, size: _secondaryIconSize),
        title: Text(libL10n.language, style: TextStyle(fontSize: _maxTextSize)),
        trailing: SizedBox(
          width: _maxElementWidth,
          child: Text(
            val.isEmpty ? context.localeNativeName : val,
            style: UIs.text13Grey.copyWith(fontSize: _maxTextSize),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () async {
          final result = await context.showPickSingleDialog<Locale>(
            title: libL10n.language,
            items: AppLocalizations.supportedLocales,
            display: (e) => e.nativeName,
            initial: val.toLocale ?? l10n.localeName.toLocale,
          );
          if (result != null) {
            _setStore.locale.set(result.code);
            await RNodes.app.notify(delay: true);
          }
        },
      ),
    );
  }

  // Widget _buildCheckUpdate() {
  //   return ListTile(
  //     leading: const Icon(Icons.update),
  //     title: Text(l10n.autoCheckUpdate),
  //     subtitle: ValueListenableBuilder(
  //       valueListenable: AppUpdateIface.newestBuild,
  //       builder: (_, val, _) {
  //         final text = switch (val) {
  //           null => '${l10n.current} v${BuildData.build}, ${l10n.clickToCheck}',
  //           > BuildData.build => libL10n.versionHasUpdate(val),
  //           _ => libL10n.versionUpdated(BuildData.build),
  //         };
  //         return Text(text, style: UIs.textGrey);
  //       },
  //     ),
  //     onTap: () => Fns.throttle(
  //       () => AppUpdateIface.doUpdate(
  //         url: Urls.appUpdateCfg,
  //         context: context,
  //         build: BuildData.build,
  //       ),
  //     ),
  //     trailing: StoreSwitch(prop: _setStore.autoCheckUpdate),
  //   );
  // }


  Widget _buildGenTitle() {
    return ListTile(
      leading: Icon(Icons.auto_awesome, size: _secondaryIconSize),
      title: Text(l10n.genChatTitle, style: TextStyle(fontSize: _maxTextSize)),
      trailing: StoreSwitch(prop: _setStore.genTitle),
    );
  }




  // Widget _buildCalcTokenLen() {
  //   return ListTile(
  //     leading: const Icon(Icons.calculate),
  //     title: Text(l10n.calcTokenLen),
  //     trailing: StoreSwitch(prop: _store.calcTokenLen),
  //   );
  // }




  Widget _buildUserName() {
    final property = _setStore.avatar;
    return ListTile(
      leading: Icon(Bootstrap.person_vcard_fill, size: _maxIconSize),
      title: Text(libL10n.name, style: TextStyle(fontSize: _maxTextSize)),
      trailing: ValBuilder(
        listenable: _setStore.avatar.listenable(),
        builder: (val) => Text(val, style: const TextStyle(fontSize: 10)),
      ),
      onTap: () async {
        final ctrl = TextEditingController(text: property.get());
        void onSave(String s) {
          property.set(s);
          context.pop();
        }

        await context.showRoundDialog(
          title: libL10n.name,
          child: Input(
            controller: ctrl,
            type: TextInputType.name,
            maxLength: 7,
            autoFocus: true,
            onSubmitted: (s) => onSave(s),
          ),
          actions: Btn.ok(onTap: () => onSave(ctrl.text)).toList,
        );
      },
    );
  }




}