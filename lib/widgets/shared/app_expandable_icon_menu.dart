import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Seyir defteri şeridinde ilk ikondan sonrakilerin boşluğu: sol 8, üst 48, sağ 8, alt 8.
const EdgeInsets kSeyirMenuIconPadding = EdgeInsets.fromLTRB(8, 48, 8, 8);

/// Seyir defteri şeridinde ilk ikonun boşluğu: sol 8, üst 8, sağ 8, alt 8.
const EdgeInsets kSeyirMenuFirstIconPadding = EdgeInsets.fromLTRB(8, 8, 8, 8);

/// Sol şeritteki bir ikon. [customChild] verilirse olduğu gibi çizilir.
class AppExpandableIconMenuItem {
  const AppExpandableIconMenuItem({
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.assetIcon,
    this.color = Colors.black54,
    this.size = 24,
    this.tooltip,
    this.label,
    this.padding = kSeyirMenuIconPadding,
    this.customChild,
  });

  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconWidget;
  final String? assetIcon;
  final Color color;
  final double size;
  final String? tooltip;
  final String? label;
  final EdgeInsetsGeometry padding;

  /// Dış sarmalayıcı eklenmeden çizilen hazır satır.
  final Widget? customChild;
}

/// Kırmızı menü düğmesi ve yanındaki açılır ikon şeridi.
///
/// Açık/kapalı durum burada kalır. [headerBuilder] düğmeyi başlığa yerleştirir;
/// [body] şeridin sağındaki içeriktir.
class AppExpandableIconMenu extends StatefulWidget {
  /// Seyir defteri şeridi: genişlik 60, 300 ms, doğrusal eğri, kaydırmalı, boşluksuz.
  const AppExpandableIconMenu.seyirDefteri({
    Key? key,
    required List<AppExpandableIconMenuItem> items,
    required Widget Function(
      BuildContext context,
      Widget menuButton,
      VoidCallback toggle,
      bool isOpen,
    ) headerBuilder,
    required Widget body,
  }) : this(
          key: key,
          items: items,
          headerBuilder: headerBuilder,
          body: body,
          expandBody: true,
          panelWidth: 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
          rowCrossAxisAlignment: CrossAxisAlignment.start,
          scrollPanel: true,
          openGap: 0,
          panelPadding: EdgeInsets.zero,
          bodyPadding: EdgeInsets.zero,
          inset: EdgeInsets.zero,
        );

  const AppExpandableIconMenu({
    super.key,
    required this.items,
    required this.headerBuilder,
    required this.body,
    this.toggleIconSize = 34,
    this.toggleIconColor = Colors.red,
    this.toggleTooltip,
    this.onToggle,
    this.initiallyOpen = false,
    this.panelWidth = 60,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
    this.expandBody = false,
    this.bodyPadding = EdgeInsets.zero,
    this.openGap = 0,
    this.keepGapWhenClosed = false,
    this.panelPadding = EdgeInsets.zero,
    this.openPanelDecoration,
    this.scrollPanel = true,
    this.inset = EdgeInsets.zero,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
    this.openRequest = 0,
  });

  final List<AppExpandableIconMenuItem> items;
  final Widget Function(
    BuildContext context,
    Widget menuButton,
    VoidCallback toggle,
    bool isOpen,
  ) headerBuilder;
  final Widget body;
  final double toggleIconSize;
  final Color toggleIconColor;
  final String? toggleTooltip;
  final ValueChanged<bool>? onToggle;
  final bool initiallyOpen;
  final double panelWidth;
  final Duration duration;
  final Curve curve;
  final bool expandBody;
  final EdgeInsetsGeometry bodyPadding;
  final double openGap;
  final bool keepGapWhenClosed;
  final EdgeInsetsGeometry panelPadding;
  final BoxDecoration? openPanelDecoration;
  final bool scrollPanel;
  final EdgeInsetsGeometry inset;
  final CrossAxisAlignment rowCrossAxisAlignment;

  /// Artınca panel açılır. Sayfa bunu artırarak menüyü dışarıdan açabilir.
  final int openRequest;

  @override
  State<AppExpandableIconMenu> createState() => _AppExpandableIconMenuState();
}

class _AppExpandableIconMenuState extends State<AppExpandableIconMenu> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  void didUpdateWidget(AppExpandableIconMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openRequest != oldWidget.openRequest) {
      _open = true;
    }
  }

  void _toggle() {
    setState(() {
      _open = !_open;
    });
    widget.onToggle?.call(_open);
  }

  Widget _menuButton() {
    return IconButton(
      tooltip: widget.toggleTooltip,
      onPressed: _toggle,
      icon: Icon(
        MdiIcons.menuOpen,
        size: widget.toggleIconSize,
        color: widget.toggleIconColor,
      ),
    );
  }

  Widget _tile(AppExpandableIconMenuItem item) {
    if (item.customChild != null) return item.customChild!;
    final Widget icon = item.iconWidget ??
        (item.assetIcon != null
            ? Image.asset(item.assetIcon!, width: item.size, height: item.size)
            : Icon(item.icon, size: item.size, color: item.color));
    final Widget graphic = item.label == null
        ? icon
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              Text(item.label!),
            ],
          );
    final Widget tap = GestureDetector(
      onTap: item.onTap,
      child: Padding(padding: item.padding, child: graphic),
    );
    if (item.tooltip == null) return tap;
    return Tooltip(message: item.tooltip!, child: tap);
  }

  Widget _panel() {
    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widget.items.map(_tile).toList(),
    );
    Widget panelChild = const SizedBox.shrink();
    if (_open) {
      panelChild = widget.scrollPanel
          ? SingleChildScrollView(
              padding: widget.panelPadding,
              child: column,
            )
          : column;
      final BoxDecoration? decoration = widget.openPanelDecoration;
      if (decoration != null) {
        panelChild = DecoratedBox(decoration: decoration, child: panelChild);
      }
    }
    return AnimatedContainer(
      duration: widget.duration,
      curve: widget.curve,
      width: _open ? widget.panelWidth : 0,
      child: panelChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showGap =
        widget.openGap > 0 && (_open || widget.keepGapWhenClosed);
    Widget row = Row(
      crossAxisAlignment: widget.rowCrossAxisAlignment,
      children: [
        _panel(),
        if (showGap) SizedBox(width: widget.openGap),
        Expanded(child: widget.body),
      ],
    );
    if (widget.inset != EdgeInsets.zero) {
      row = Padding(padding: widget.inset, child: row);
    }
    final Widget pane = widget.expandBody
        ? Expanded(child: row)
        : Padding(padding: widget.bodyPadding, child: row);
    return Column(
      children: [
        widget.headerBuilder(context, _menuButton(), _toggle, _open),
        pane,
      ],
    );
  }
}
