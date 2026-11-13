// EyeControl home screen (AKM12): neon dashboard replacing the stock home layout.
// It only drives existing features: connect(), peer list, server status, own ID/password.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart' hide Dialog;
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

const Color _kNeon = Color(0xFF38BDF8);
const Color _kNeonSoft = Color(0xFF7DD3FC);
const Color _kNight = Color(0xFF050B14);
const Color _kPanel = Color(0xFF0B1724);
const Color _kOnline = Color(0xFF22C55E);

class EyeControlHome extends StatefulWidget {
  const EyeControlHome({Key? key}) : super(key: key);

  @override
  State<EyeControlHome> createState() => _EyeControlHomeState();
}

class _EyeControlHomeState extends State<EyeControlHome> {
  Timer? _timer;
  Timer? _statusTimer;
  String _version = '';
  int _queriedCount = -1;

  Peers get _peers => gFFI.recentPeersModel;

  @override
  void initState() {
    super.initState();
    _peers.addListener(_onPeers);
    bind.mainLoadRecentPeers();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    // The stock status bar (OnlineStatusWidget) is not on this screen: poll the
    // rendezvous status ourselves, like it does, so "Connecté" stays accurate.
    _updateStatus();
    _statusTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateStatus());
    bind.mainGetVersion().then((v) {
      if (mounted) setState(() => _version = v);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    _peers.removeListener(_onPeers);
    super.dispose();
  }

  void _onPeers() {
    if (_peers.peers.length != _queriedCount) {
      _queriedCount = _peers.peers.length;
      _queryOnlines();
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateStatus() async {
    try {
      final status =
          jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
      final statusNum = status['status_num'] as int;
      if (statusNum == 0) {
        stateGlobal.svcStatus.value = SvcStatus.connecting;
      } else if (statusNum == 1) {
        stateGlobal.svcStatus.value = SvcStatus.ready;
      } else {
        stateGlobal.svcStatus.value = SvcStatus.notReady;
      }
      final count = status['video_conn_count'];
      if (count is int) stateGlobal.videoConnCount.value = count;
    } catch (_) {}
  }

  void _refresh() {
    bind.mainLoadRecentPeers();
    _queryOnlines();
  }

  void _queryOnlines() {
    final ids = _peers.peers
        .map((p) => p.id)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isNotEmpty) {
      bind.queryOnlines(ids: ids);
    }
  }

  static bool _isMobile(Peer p) {
    final s = p.platform.toLowerCase();
    return s.contains('android') || s.contains('ios');
  }

  List<Peer> _devices(bool mobile) =>
      _peers.peers.where((p) => _isMobile(p) == mobile).toList();

  static String _peerName(Peer p) {
    if (p.alias.isNotEmpty) return p.alias;
    if (p.hostname.isNotEmpty) return p.hostname;
    return p.id;
  }

  // ------------------------------------------------------------------ actions

  void _connect(String id,
      {bool isFileTransfer = false, bool isTerminal = false}) {
    final clean = id.replaceAll(' ', '').trim();
    if (clean.isEmpty) return;
    connect(context, clean,
        isFileTransfer: isFileTransfer, isTerminal: isTerminal);
  }

  Future<void> _askId(String title, IconData icon,
      {bool isFileTransfer = false, bool isTerminal = false}) async {
    final controller = TextEditingController();
    final known = _peers.peers.take(6).toList();
    await showDialog(
      context: context,
      builder: (ctx) {
        void submit(String id) {
          final clean = id.replaceAll(' ', '').trim();
          if (clean.isEmpty) return;
          Navigator.of(ctx).pop();
          _connect(clean,
              isFileTransfer: isFileTransfer, isTerminal: isTerminal);
        }

        return Dialog(
          backgroundColor: _kPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _kNeon.withOpacity(0.6)),
          ),
          child: SizedBox(
            width: 440,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(icon, color: _kNeon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, letterSpacing: 1),
                    decoration: InputDecoration(
                      hintText: "ID de l'appareil (ex. 482 913 507)",
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.35)),
                      filled: true,
                      fillColor: const Color(0xFF0F2030),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _kNeon.withOpacity(0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kNeon),
                      ),
                    ),
                    onSubmitted: submit,
                  ),
                  if (known.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: known
                          .map((p) => ActionChip(
                                backgroundColor: const Color(0xFF0F2030),
                                side: BorderSide(
                                    color: _kNeon.withOpacity(0.35)),
                                avatar: Icon(Icons.circle,
                                    size: 10,
                                    color: p.online
                                        ? _kOnline
                                        : Colors.white24),
                                label: Text(_peerName(p),
                                    style: const TextStyle(
                                        color: Colors.white70)),
                                onPressed: () => submit(p.id),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Annuler',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kNeon,
                          foregroundColor: _kNight,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => submit(controller.text),
                        child: const Text('Se connecter',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDevices(bool mobile) async {
    final title = mobile ? 'Smartphones' : 'Ordinateurs';
    await showDialog(
      context: context,
      builder: (ctx) {
        final list = _devices(mobile);
        Widget action(IconData icon, String tip, VoidCallback onTap) =>
            IconButton(
              tooltip: tip,
              icon: Icon(icon, color: _kNeonSoft, size: 20),
              onPressed: () {
                Navigator.of(ctx).pop();
                onTap();
              },
            );
        return Dialog(
          backgroundColor: _kPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _kNeon.withOpacity(0.6)),
          ),
          child: SizedBox(
            width: 580,
            height: 460,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(mobile ? Icons.smartphone : Icons.desktop_windows,
                        color: _kNeon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Text(
                              mobile
                                  ? "Aucun smartphone pour l'instant.\nIls apparaissent ici après une première connexion."
                                  : "Aucun ordinateur pour l'instant.\nIls apparaissent ici après une première connexion.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: _kNeon.withOpacity(0.12)),
                            itemBuilder: (_, i) {
                              final p = list[i];
                              return ListTile(
                                leading: Icon(Icons.circle,
                                    size: 12,
                                    color:
                                        p.online ? _kOnline : Colors.white24),
                                title: Text(_peerName(p),
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                    '${p.id}${p.platform.isNotEmpty ? '  ·  ${p.platform}' : ''}',
                                    style: const TextStyle(
                                        color: Colors.white54)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    action(Icons.screen_share_outlined,
                                        "Prendre la main", () => _connect(p.id)),
                                    if (!mobile)
                                      action(Icons.terminal, 'Terminal distant',
                                          () => _connect(p.id, isTerminal: true)),
                                    action(Icons.folder_outlined,
                                        'Transfert de fichiers',
                                        () => _connect(p.id,
                                            isFileTransfer: true)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ layout

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNight,
      child: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _NeonBackgroundPainter())),
          Column(
            children: [
              const SizedBox(height: 14),
              _header(),
              Expanded(child: Center(child: _tiles())),
              _bottomBar(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Image.asset(
          'assets/logo_hero.png',
          height: 118,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(height: 118),
        ),
        const SizedBox(height: 6),
        Text(
          'Prise en main à distance  •  Ordinateurs & Smartphones',
          style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 14,
              letterSpacing: 0.3),
        ),
      ],
    );
  }

  Widget _onlineLabel(bool mobile) {
    final all = _devices(mobile);
    if (all.isEmpty) {
      return Text('Aucun appareil',
          style: TextStyle(color: Colors.white.withOpacity(0.55)));
    }
    final online = all.where((p) => p.online).length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: online > 0 ? _kOnline : Colors.white24),
        const SizedBox(width: 6),
        Text('$online en ligne / ${all.length}',
            style: TextStyle(color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _tiles() {
    const gap = SizedBox(height: 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          _NeonTile(
            icon: Icons.desktop_windows_outlined,
            title: 'Ordinateurs',
            subtitle: _onlineLabel(false),
            onTap: () => _showDevices(false),
          ),
          gap,
          _NeonTile(
            icon: Icons.terminal,
            title: 'Terminal distant',
            subtitle: Text('CMD / PowerShell',
                style: TextStyle(color: Colors.white.withOpacity(0.75))),
            onTap: () => _askId('Terminal distant', Icons.terminal,
                isTerminal: true),
          ),
        ]),
        const SizedBox(width: 22),
        _ConnectOrb(
            onTap: () =>
                _askId('Prendre la main', Icons.play_arrow_rounded)),
        const SizedBox(width: 22),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _NeonTile(
            icon: Icons.smartphone,
            title: 'Smartphones',
            subtitle: _onlineLabel(true),
            onTap: () => _showDevices(true),
          ),
          gap,
          _NeonTile(
            icon: Icons.folder_outlined,
            title: 'Transfert de fichiers',
            subtitle: const Icon(Icons.swap_vert, color: _kNeonSoft, size: 20),
            onTap: () => _askId('Transfert de fichiers', Icons.folder_outlined,
                isFileTransfer: true),
          ),
        ]),
      ],
    );
  }

  Widget _pill(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A28).withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kNeon.withOpacity(0.28)),
      ),
      child: child,
    );
  }

  Widget _sep() => Container(
        width: 1,
        height: 18,
        color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(translate('Copied'));
  }

  Widget _bottomBar(BuildContext context) {
    final model = gFFI.serverModel;
    const label = TextStyle(color: Colors.white60, fontSize: 13);
    const value = TextStyle(
        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 14, 14),
      child: Row(
        children: [
          _pill(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final st = stateGlobal.svcStatus.value;
                final ready = st == SvcStatus.ready;
                final text = ready
                    ? 'Connecté'
                    : (st == SvcStatus.connecting ? 'Connexion…' : 'Hors ligne');
                final color = ready
                    ? _kOnline
                    : (st == SvcStatus.connecting
                        ? Colors.orangeAccent
                        : Colors.redAccent);
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 8),
                  Text(text, style: TextStyle(color: color, fontSize: 14)),
                ]);
              }),
              _sep(),
              const Text('Mon ID  ', style: label),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: model.serverId,
                builder: (_, v, __) => InkWell(
                  onTap: () => _copy(v.text),
                  child: Text(v.text, style: value),
                ),
              ),
              _sep(),
              const Text('Mot de passe  ', style: label),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: model.serverPasswd,
                builder: (_, v, __) => InkWell(
                  onTap: () => _copy(v.text),
                  child: Text(v.text, style: value),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => bind.mainUpdateTemporaryPassword(),
                child: const Tooltip(
                  message: 'Nouveau mot de passe',
                  child: Icon(Icons.refresh, size: 18, color: Colors.white54),
                ),
              ),
            ],
          )),
          const Spacer(),
          if (!bind.mainIsInstalled()) ...[
            InkWell(
              onTap: () => bind.mainGotoInstall(),
              child: _pill(const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_rounded, size: 18, color: _kNeon),
                SizedBox(width: 6),
                Text('Installer', style: TextStyle(color: Colors.white)),
              ])),
            ),
            const SizedBox(width: 10),
          ],
          ChangeNotifierProvider.value(
            value: model,
            child: Consumer<ServerModel>(
              builder: (_, m, __) => _pill(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq, size: 18, color: _kNeon),
                  const SizedBox(width: 8),
                  Text('Sessions : ${m.clients.length}',
                      style: const TextStyle(color: Colors.white)),
                ],
              )),
            ),
          ),
          const SizedBox(width: 12),
          if (_version.isNotEmpty)
            Text('v$_version',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          IconButton(
            tooltip: 'Paramètres',
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => DesktopTabPage.onAddSetting(),
          ),
        ],
      ),
    );
  }
}

class _NeonTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget subtitle;
  final VoidCallback onTap;

  const _NeonTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  State<_NeonTile> createState() => _NeonTileState();
}

class _NeonTileState extends State<_NeonTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 250,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0E2A44).withOpacity(0.92),
                const Color(0xFF081522).withOpacity(0.92),
              ],
            ),
            border: Border.all(
                color: _kNeon.withOpacity(_hover ? 0.95 : 0.6), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: _kNeon.withOpacity(_hover ? 0.45 : 0.22),
                blurRadius: _hover ? 28 : 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 40, color: _kNeonSoft),
              const SizedBox(height: 8),
              Text(widget.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              widget.subtitle,
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectOrb extends StatefulWidget {
  final VoidCallback onTap;

  const _ConnectOrb({required this.onTap});

  @override
  State<_ConnectOrb> createState() => _ConnectOrbState();
}

class _ConnectOrbState extends State<_ConnectOrb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 176,
          height: 176,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF155E8C), Color(0xFF0A2238), Color(0xFF061322)],
              stops: [0.0, 0.7, 1.0],
            ),
            border: Border.all(
                color: _kNeon.withOpacity(_hover ? 1.0 : 0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: _kNeon.withOpacity(_hover ? 0.7 : 0.45),
                blurRadius: _hover ? 44 : 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 64, color: Colors.white),
              SizedBox(height: 2),
              Text('Se connecter',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Night-blue background: soft centre glow, eye-shaped arcs and a dotted wave.
class _NeonBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0B3A66).withOpacity(0.55),
          const Color(0x00050B14),
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(w / 2, h * 0.42), radius: w * 0.62));
    canvas.drawRect(Offset.zero & size, glow);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kNeon.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    final upper = Rect.fromCenter(
        center: Offset(w / 2, h * 0.78), width: w * 1.12, height: h * 1.1);
    canvas.drawArc(upper, math.pi * 1.1, math.pi * 0.8, false, arc);
    final lower = Rect.fromCenter(
        center: Offset(w / 2, h * 0.05), width: w * 1.05, height: h * 1.25);
    arc.color = _kNeon.withOpacity(0.18);
    canvas.drawArc(lower, math.pi * 0.12, math.pi * 0.76, false, arc);

    final dot = Paint();
    const rows = 14;
    for (var row = 0; row < rows; row++) {
      final fade = 1 - row / rows;
      dot.color = _kNeon.withOpacity(0.08 + 0.32 * fade);
      for (double x = 0; x <= w; x += 9) {
        final y = h -
            78 +
            row * 6 +
            math.sin(x / w * math.pi * 3 + row * 0.35) * 18 * fade;
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
