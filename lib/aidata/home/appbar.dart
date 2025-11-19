part of 'home.dart';

final class _CustomAppBar extends CustomAppBar {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    // Minimalist Title Logic
    final title = _appbarTitleVN.listenVal(
      (val) {
        return AnimatedSwitcher(
          duration: _durationMedium,
          switchInCurve: Easing.standardDecelerate,
          switchOutCurve: Easing.standardDecelerate,
          transitionBuilder: (child, animation) => SlideTransitionX(
            position: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          // Removed fixed SizedBox width to allow full usage of tiny screens
          child: Text(
            val ?? l10n.untitled,
            key: ValueKey(val), // Added Key for proper animation
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: UIs.text15.copyWith(height: 1.2), // Tighten line height
          ),
        );
      },
    );

    // Minimalist Subtitle Logic
    final subtitle = Cfg.vn.listen(() {
      return Cfg.chatType.listenVal((typ) {
        final model = typ.model ?? 'model';
        return Text(
          model.isEmpty ? libL10n.empty : model,
          key: ValueKey(model),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          // Slightly smaller font for better hierarchy on small screens
          style: UIs.text12Grey.copyWith(fontSize: 10, height: 1.0), 
        );
      });
    });

    return CustomAppBar(
      centerTitle: false,
      // Reduced padding on leading button if possible within Btn.icon, 
      // otherwise kept standard to ensure touch targets remain accessible.
      leading: Btn.icon(
        icon: const Icon(Icons.settings, size: 20), // Slightly smaller icon
        onTap: () async {
          final ret = await SettingsPage.route.go(context);
          if (ret?.restored == true) {
            HomePage.afterRestore();
          }
        },
      ),
      title: GestureDetector(
        onLongPress: () => DebugPage.route.go(context),
        onTap: () => _onSwitchModel(context, notifyKey: true),
        child: Container(
          // Ensure hit test covers the area but doesn't force width
          color: Colors.transparent, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: title),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: subtitle),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 10, // Minimal icon size
                    color: Colors.grey,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: _curPage,
          builder: (_, page, _) => page.buildAppbarActions(context),
        )
      ],
    );
  }
}

// Future<void> _onLongTapSetting(
//   BuildContext context,
//   HiveStore store,
// ) async {
//   final map = store.box.toJson(includeInternal: false);
//   final keys = map.keys;

//   /// Encode [map] to String with indent `\t`
//   final text = const JsonEncoder.withIndent('  ').convert(map);
//   final result = await PlainEditPage.route.go(
//     context,
//     args: PlainEditPageArgs(
//       initialText: text,
//       title: store.box.name,
//     ),
//   );
//   if (result == null) return;

//   try {
//     final newSettings = json.decode(result) as Map<String, dynamic>;
//     store.box.putAll(newSettings);
//     final newKeys = newSettings.keys;
//     final removedKeys = keys.where((e) => !newKeys.contains(e));
//     for (final key in removedKeys) {
//       Stores.setting.box.delete(key);
//     }
//   } catch (e, s) {
//     context.showErrDialog(e, s);
//   }
// }
