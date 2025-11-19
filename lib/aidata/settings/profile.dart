part of 'setting.dart';

final class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

final class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    ApiBalance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        spacing: 6,
        children: [
          _buildChatSection(),
        ],
      ),
    );
  }

  static const refreshIcon = IconButton(
    onPressed: ApiBalance.refresh,
    icon: Icon(Icons.refresh),
    iconSize: 15,
  );

  Widget _buildBalance() {
    return ApiBalance.balance.listenVal((val) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.account_balance_wallet, size: 15),
        title: Text(l10n.balance, style: const TextStyle(fontSize: 10)),
        subtitle: Text(val.state ?? l10n.unsupported, style: UIs.text13Grey),
        trailing: val.loading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : refreshIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      );
    });
  }

  Widget _buildChatSection() {
    return Cfg.vn.listenVal((cfg) {
      final children = [
        _buildSwitchCfg(cfg),
        _buildBalance(),
        _buildOpenAIKey(cfg.key),
        _buildOpenAIUrl(cfg.url),
        _buildOpenAIModels(cfg),
                _buildPrompt(cfg.prompt),
        _buildHistoryLength(cfg.historyLen),

      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              l10n.chat.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                letterSpacing: 0.3,
                fontSize: 10,
              ),
            ),
          ),
          ...children.map((e) => e.cardx),
        ],
      );
    });
  }


  Widget _buildSwitchCfg(ChatConfig cfg) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.switch_account, size: 15),
      title: Text(l10n.profile, style: const TextStyle(fontSize: 10)),
      subtitle: Text(cfg.displayName, style: UIs.textGrey, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!cfg.isDefault)
              _iconBtn(
                icon: const Icon(Icons.delete, size: 14),
                onTap: () {
                  context.showRoundDialog(
                    title: l10n.attention,
                    child: Text(l10n.delFmt(cfg.name, l10n.profile)),
                    actions: Btn.ok(
                      onTap: () {
                        Stores.config.delete(cfg.id);
                        context.pop();
                        Cfg.switchToDefault(context);
                      },
                      red: true,
                    ).toList,
                  );
                },
              ),
            _iconBtn(
              icon: const Icon(Icons.edit, size: 14),
              onTap: () {
                final ctrl = TextEditingController(text: cfg.name);
                context.showRoundDialog(
                  title: libL10n.edit,
                  child: Input(
                    controller: ctrl,
                    label: libL10n.name,
                    autoFocus: true,
                  ),
                  actions: Btn.ok(
                    onTap: () {
                      final name = ctrl.text;
                      if (name.isEmpty) return;
                      final newCfg = cfg.copyWith(name: name);
                      newCfg.save();
                      Cfg.setTo(cfg: newCfg);
                      context.pop();
                    },
                  ).toList,
                );
              },
            ),
            _iconBtn(
              icon: const Icon(OctIcons.arrow_switch, size: 14),
              onTap: () => Cfg.showPickProfileDialog(context),
            ),
            _iconBtn(
              icon: const Icon(Icons.add, size: 14),
              onTap: () async {
                final ctrl = TextEditingController();
                final ok = await context.showRoundDialog(
                  title: libL10n.add,
                  child: Input(
                    controller: ctrl,
                    label: libL10n.name,
                    autoFocus: true,
                  ),
                  actions: Btnx.oks,
                );
                if (ok != true) return;
                final clipboardData = await Pfs.paste();
                var (key, url) = ('', ChatConfigX.defaultUrl);
                if (clipboardData != null) {
                  if (clipboardData.startsWith('https://')) {
                    url = clipboardData;
                  } else if (clipboardData.startsWith('sk-')) {
                    key = clipboardData;
                  }
                }
                final newCfg = Cfg.current.copyWith(
                  id: shortid.generate(),
                  name: ctrl.text,
                  key: key,
                  url: url,
                );
                newCfg.save();
                Cfg.setTo(cfg: newCfg);
              },
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _iconBtn({required Icon icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: icon,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildOpenAIKey(String val) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.vpn_key, size: 15),
      title: Text(l10n.secretKey, style: const TextStyle(fontSize: 10)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 50),
        child: Text(
          val.isEmpty ? libL10n.empty : '${val.substring(0, 3)}***',
          style: UIs.textGrey,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      onTap: () async {
        final ctrl = TextEditingController(text: val);
        final result = await context.showRoundDialog<String>(
          title: libL10n.edit,
          child: Input(
            controller: ctrl,
            hint: 'sk-xxx',
            maxLines: 3,
            autoFocus: true,
          ),
          actions: Btn.ok(onTap: () => context.pop(ctrl.text)).toList,
        );
        if (result == null) return;
        Cfg.setTo(cfg: Cfg.current.copyWith(key: result));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildOpenAIUrl(String val) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.link, size: 15),
      title: const Text('URL', style: TextStyle(fontSize: 10)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 50),
        child: Text(
          val.isEmpty ? libL10n.empty : val.replaceFirst(RegExp('https?://'), ''),
          style: UIs.text13Grey,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      onTap: () async {
        final ctrl = TextEditingController(text: val);
        String? result = await context.showRoundDialog<String>(
          title: libL10n.edit,
          child: Input(
            controller: ctrl,
            hint: ChatConfigX.defaultUrl,
            maxLines: 2,
            autoFocus: true,
          ),
          actions: Btn.ok(onTap: () => context.pop(ctrl.text)).toList,
        );
        if (result == null) return;
        if (result == "https://api.groq.com/openai/v1") {
          result = "https://api.groq.com/openai/v1/chat/completions";
        }
        if (result == "https://generativelanguage.googleapis.com/v1beta") {
          result = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions";
        }

        final isApiUrl = ChatConfigX.apiUrlReg.hasMatch(result ?? result.toString());
        final endsWithV1 = result?.endsWith('/v1') ?? false;
        final isGithubModels = result == Urls.githubModels;
        final showDialog = !isApiUrl && (!endsWithV1 && !isGithubModels);
        if (showDialog) {
          final sure = await context.showRoundDialog(
            title: l10n.attention,
            child: Text(l10n.apiUrlV1Tip),
            actions: Btnx.okReds,
          );
          if (sure != true) return;
        }

        Cfg.setTo(cfg: Cfg.current.copyWith(url: result ?? result.toString()));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildOpenAIModels(ChatConfig cfg) {
    return Cfg.models.listen(() {
      return Theme(
        data: Theme.of(context).copyWith(
          expansionTileTheme: const ExpansionTileThemeData(),
        ),
        child: ExpandTile(
          leading: const Icon(Icons.model_training, size: 15),
          title: Text(l10n.model, style: const TextStyle(fontSize: 10)),
          children: [
            _buildModelTile('Chat', cfg.model, (m) => Cfg.setTo(cfg: cfg.copyWith(model: m))),
            _buildModelTile('Image', cfg.imgModel ?? '', (m) => Cfg.setTo(cfg: cfg.copyWith(imgModel: m))),
            _buildModelTile('Tasker Admin', cfg.imgModel ?? '', (m) => Cfg.setTo(cfg: cfg.copyWith(imgModel: m))),
            _buildModelTile('Alternative', cfg.altrModel ?? '', (m) => Cfg.setTo(cfg: cfg.copyWith(altrModel: m))),
            _buildModelTile('Transcribe', cfg.trnscrbModel ?? '', (m) => Cfg.setTo(cfg: cfg.copyWith(trnscrbModel: m))),
            _buildModelTile('Voice', cfg.audioModel ?? '', (m) => Cfg.setTo(cfg: cfg.copyWith(audioModel: m))),
            _buildModelTile('Worker', cfg.wrkrModel ?? '', (m) => Cfg.setTo(cfg: cfg.copyWith(wrkrModel: m))),
          ],
        ),
      );
    });
  }

  Widget _buildModelTile(String label, String value, Function(String) onSelected) {
    return ListTile(
      dense: true,
      leading: const SizedBox(width: 20),
      title: Text(label, style: const TextStyle(fontSize: 11)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 50),
        child: Text(value, style: UIs.text13Grey, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onTap: () => Cfg.showPickModelDialog(context, initial: value, onSelected: onSelected),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildPrompt(String val) {
    return Column(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.abc, size: 20),
          title: Text(l10n.promptsSettingsItem, style: const TextStyle(fontSize: 10)),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 50, maxHeight: 60),
            child: Text(
              val.isEmpty ? libL10n.empty : val,
              style: UIs.textGrey,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          onTap: () async {
            final ctrl = TextEditingController(text: val);
            final result = await context.showRoundDialog<String>(
              title: libL10n.edit,
              child: Input(controller: ctrl, maxLines: 8, autoFocus: true),
              actions: Btn.ok(onTap: () => context.pop(ctrl.text)).toList,
            );
            if (result == null) return;
            Cfg.setTo(cfg: Cfg.current.copyWith(prompt: result));
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ],
    );
  }

  Widget _buildHistoryLength(int val) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history, size: 15),
      title: TipText(l10n.chatHistoryLength, l10n.chatHistoryTip, textStyle: const TextStyle(fontSize: 10)),
      trailing: Text(val.toString(), style: UIs.text13Grey),
      onTap: () async {
        final ctrl = TextEditingController(text: val.toString());
        final result = await context.showRoundDialog<String>(
          title: libL10n.edit,
          child: Input(
            controller: ctrl,
            hint: '7',
            autoFocus: true,
            type: TextInputType.number,
          ),
          actions: Btn.ok(onTap: () => context.pop(ctrl.text)).toList,
        );
        if (result == null) return;
        final newVal = int.tryParse(result);
        if (newVal == null) {
          context.showSnackBar('Invalid number: $result');
          return;
        }
        Cfg.setTo(cfg: Cfg.current.copyWith(historyLen: newVal));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildQuickShare() {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.share, size: 20),
      title: TipText(libL10n.share, l10n.quickShareTip, 
      textStyle:  TextStyle(fontSize: 10)),
      trailing: const Icon(Icons.keyboard_arrow_right, size: 15),
      onTap: () {
        final url = Cfg.current.shareUrl;
        if (url.isEmpty) return;
        Pfs.shareStr(url);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  @override
  bool get wantKeepAlive => true;
}