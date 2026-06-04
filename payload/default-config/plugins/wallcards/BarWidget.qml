import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
  id: root

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "none"
  property var pluginApi: null
  property ShellScreen screen
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0
  property string widgetId: ""

  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth
  colorBg: Style.capsuleColor
  colorFg: Color.resolveColorKey(iconColorKey)
  customRadius: Style.radiusL
  icon: "cards"
  tooltipDirection: BarService.getTooltipDirection(screen?.name)
  tooltipText: pluginApi?.tr("widget.tooltip")

  onClicked: {
    if (pluginApi) {
      root.pluginApi?.mainInstance.toggle();
    }
  }
  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen);
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "widget-settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }
}
