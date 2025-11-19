import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/generated/l10n/lib_l10n.dart';
import 'package:flutter/material.dart';
import 'package:studio_packet/aidata/data/store/all.dart';
import 'package:studio_packet/aidata/home/home.dart';

import '../aidata/data/res/l10n.dart';
import '../aidata/generated/l10n/l10n.dart';
import 'package:responsive_framework/responsive_framework.dart';


class RightUtilityPanel extends StatelessWidget {
  const RightUtilityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RNodes.app.listen(() => _buildApp(context));
  }

  Widget _buildApp(BuildContext context) {
    UIs.colorSeed = Color(Stores.setting.themeColorSeed.get());
    final locale = Stores.setting.locale.get();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale.toLocale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        LibLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: LocaleUtil.resolve,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: UIs.colorSeed,
      ).toAmoled.fixWindowsFont,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child ?? UIs.placeholder,
        breakpoints: const [
          Breakpoint(start: 0, end: 650, name: MOBILE),
          Breakpoint(start: 651, end: 900, name: TABLET),
          Breakpoint(start: 901, end: 1920, name: DESKTOP),
        ],
      ),
      home: VirtualWindowFrame(
        child: Builder(
          builder: (context) {
            final l10n_ = AppLocalizations.of(context);
            if (l10n_ != null) l10n = l10n_;
            context.setLibL10n();

            return const HomePage();
          },
        ),
      ),
    );
  }
}