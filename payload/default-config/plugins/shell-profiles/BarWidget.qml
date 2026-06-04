import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Plugin API
  property var pluginApi: null

  // Required plugin properties for Bar Widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Per-screen bar properties
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Settings with defaults from manifest
  readonly property string widgetIcon: pluginApi?.pluginSettings?.icon || pluginApi?.manifest?.metadata?.defaultSettings?.icon || "bookmark"

  readonly property string iconColorKey: pluginApi?.pluginSettings?.iconColor || pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "primary"

  readonly property color resolvedIconColor: Color.resolveColorKeyOptional(iconColorKey)

  readonly property color iconColor: mouseArea.containsMouse ? Color.mOnHover : (resolvedIconColor.a > 0 ? resolvedIconColor : Color.mOnSurface)

  // Content dimensions
  readonly property real contentWidth: Style.capsuleHeight
  readonly property real contentHeight: Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // Shortcut to the main service instance
  readonly property var service: pluginApi?.mainInstance

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: content
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: root.widgetIcon
        color: root.iconColor
        applyUiScale: true

        Behavior on color {
          enabled: !Color.isTransitioning
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.InOutQuad
          }
        }
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);
                   if (action === "widget-settings") {
                     BarService.openPluginSettings(screen, pluginApi.manifest);
                   }
                 }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      TooltipService.show(root, pluginApi?.tr("widget.tooltip"), BarService.getTooltipDirection());
    }
    onExited: {
      TooltipService.hide();
    }
    onClicked: function (mouse) {
      if (mouse.button === Qt.LeftButton) {
        pluginApi?.togglePanel(root.screen, root);
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }

  Component.onCompleted: {
    Logger.i("ShellProfiles", "BarWidget loaded on", screenName);
  }
}
