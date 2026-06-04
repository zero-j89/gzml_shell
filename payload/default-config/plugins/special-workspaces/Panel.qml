import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string expandDirection: cfg.expandDirection ?? defaults.expandDirection
    readonly property bool isVertical: expandDirection === "up" || expandDirection === "down"

    readonly property string panelBackgroundColor: cfg.panelBackgroundColor ?? defaults.panelBackgroundColor ?? "none"
    readonly property bool panelBackgroundEnabled: cfg.panelBackgroundEnabled ?? defaults.panelBackgroundEnabled ?? true

    // Visibility settings
    readonly property bool hideEmpty: cfg.hideEmptyWorkspaces ?? defaults.hideEmptyWorkspaces

    // Reusing the same pill size math using the screen the panel is attached to
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(pluginApi?.panelOpenScreen?.name)
    readonly property real pillSpacing: Style.marginXS

    readonly property var configuredWorkspaces: {
        var list = cfg.workspaces ?? defaults.workspaces;
        if (!list || !Array.isArray(list)) list = defaults.workspaces || [];
        var result = [];
        for (var i = 0; i < list.length; i++) {
            result.push({
                "name": "special:" + list[i].name,
                "shortName": list[i].name,
                "icon": list[i].icon,
                "symbolColor": list[i].symbolColor ?? "none",
                "showPill": list[i].showPill ?? true,
                "pillColor": list[i].pillColor ?? "primary",
                "size": list[i].size ?? 0.9,
                "borderRadius": list[i].borderRadius ?? 1.0,
                "focusColor": list[i].focusColor ?? "primary"
            });
        }
        return result;
    }

    readonly property var activeWorkspaceNames: pluginApi?.mainInstance?.activeWorkspaceNames || ({})
    readonly property string internalActiveSpecial: pluginApi?.mainInstance?.activeSpecialByMonitor?.[pluginApi?.panelOpenScreen?.name] ?? ""

    // Panel size calculation — iterate to handle per-workspace sizes
    readonly property real maxPillSize: {
        var maxSize = 0;
        for (var i = 0; i < configuredWorkspaces.length; i++) {
            var wsSize = configuredWorkspaces[i].size ?? 0.9;
            var pillSize = Math.round(capsuleHeight * wsSize / 2) * 2;
            if (pillSize > maxSize) maxSize = pillSize;
        }
        return maxSize;
    }

    readonly property real fullSize: {
        var pillsSize = 0;
        var count = 0;
        for (var i = 0; i < configuredWorkspaces.length; i++) {
            var ws = configuredWorkspaces[i];
            if (hideEmpty && activeWorkspaceNames[ws.name] !== true) continue;
            pillsSize += Math.round(capsuleHeight * (ws.size ?? 0.9) / 2) * 2;
            count++;
        }
        if (count > 0) pillsSize += pillSpacing * (count - 1);
        return pillsSize;
    }

    property real contentPreferredWidth: isVertical ? maxPillSize + Style.marginS * 2 : fullSize + Style.marginS * 2
    property real contentPreferredHeight: isVertical ? fullSize + Style.marginS * 2 : maxPillSize + Style.marginS * 2

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: root.contentPreferredWidth
            height: root.contentPreferredHeight
            color: {
                if (!root.panelBackgroundEnabled) return "transparent";
                if (root.panelBackgroundColor === "none") return Color.mOnSurface;
                return Color.resolveColorKey(root.panelBackgroundColor);
            }
            radius: Style.radiusL
            border.color: root.panelBackgroundEnabled ? Color.mOutline : "transparent"
            border.width: root.panelBackgroundEnabled ? Style.borderS : 0

            // Render either row or column based on direction
            RowLayout {
                visible: !root.isVertical
                anchors.centerIn: parent
                spacing: root.pillSpacing
                layoutDirection: root.expandDirection === "left" ? Qt.RightToLeft : Qt.LeftToRight

                Repeater {
                    model: root.configuredWorkspaces
                    WorkspacePill {
                        visible: (!root.hideEmpty || root.activeWorkspaceNames[modelData.name] === true)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            ColumnLayout {
                visible: root.isVertical
                anchors.centerIn: parent
                spacing: root.pillSpacing

                Repeater {
                    model: root.configuredWorkspaces
                    WorkspacePill {
                        visible: (!root.hideEmpty || root.activeWorkspaceNames[modelData.name] === true)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    component WorkspacePill: Rectangle {
        id: wsPill
        required property var modelData

        readonly property bool hasPill: modelData.showPill ?? true
        readonly property real wsPillSize: Math.round(root.capsuleHeight * (modelData.size ?? 0.9) / 2) * 2
        readonly property real wsIconSize: Style.toOdd(wsPillSize * 0.55)
        readonly property real wsBorderRadius: modelData.borderRadius ?? 1.0
        readonly property string wsSymbolColor: modelData.symbolColor ?? "none"
        readonly property string wsPillColor: modelData.pillColor ?? "primary"
        readonly property string wsFocusColor: modelData.focusColor ?? "primary"

        implicitWidth: wsPillSize
        implicitHeight: wsPillSize
        radius: wsPillSize / 2 * wsBorderRadius
        color: {
            if (wsPillMouse.containsMouse) return hasPill ? Color.mHover : Color.mTertiary;
            if (isFocused) {
                if (wsFocusColor === "none") return Color.mOnSurface;
                return Color.resolveColorKey(wsFocusColor);
            }
            if (!hasPill) return "transparent";
            if (wsPillColor === "none") return Color.mOnSurface;
            return Color.resolveColorKey(wsPillColor);
        }

        readonly property bool isActive: root.activeWorkspaceNames[modelData.name] === true
        readonly property bool isFocused: root.internalActiveSpecial === modelData.name

        opacity: isActive ? 1.0 : 0.2

        Behavior on color { ColorAnimation { duration: Style.animationFast } }

        NIcon {
            icon: wsPill.modelData.icon
            pointSize: wsPill.wsIconSize
            applyUiScale: false
            color: {
                if (wsPillMouse.containsMouse) return wsPill.hasPill ? Color.mOnHover : Color.mOnTertiary;
                if (!wsPill.isActive) return Color.mOnSurface;
                if (wsPill.wsSymbolColor !== "none") return Color.resolveColorKey(wsPill.wsSymbolColor);
                if (wsPill.isFocused) {
                    if (wsPill.wsFocusColor === "none") return Color.mSurface;
                    return Color.resolveOnColorKey(wsPill.wsFocusColor);
                }
                if (wsPill.hasPill) {
                    if (wsPill.wsPillColor === "none") return Color.mSurface;
                    return Color.resolveOnColorKey(wsPill.wsPillColor);
                }
                return Color.mOnSurface;
            }
            anchors.centerIn: parent
        }

        MouseArea {
            id: wsPillMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: function (mouse) {
                Hyprland.dispatch(`togglespecialworkspace ${wsPill.modelData.shortName}`);
                if (pluginApi) pluginApi.closePanel(pluginApi.panelOpenScreen);
            }
        }

        Behavior on opacity { NumberAnimation { duration: Style.animationFast } }
    }
}
