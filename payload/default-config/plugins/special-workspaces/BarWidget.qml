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
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    visible: CompositorService.isHyprland

    z: 999

    readonly property string mainIcon: cfg.mainIcon ?? defaults.mainIcon
    readonly property string expandDirection: cfg.expandDirection ?? defaults.expandDirection
    readonly property bool isVertical: expandDirection === "up" || expandDirection === "down"

    readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"

    readonly property bool needsPanel: (isBarVertical && (expandDirection === "left" || expandDirection === "right")) ||
                                       (!isBarVertical && (expandDirection === "up" || expandDirection === "down"))

    // Drawer button settings
    readonly property bool showDrawer: cfg.drawer ?? defaults.drawer
    readonly property string priSymbolColor: cfg.primarySymbolColor ?? defaults.primarySymbolColor
    readonly property bool priShowPill: cfg.primaryShowPill ?? defaults.primaryShowPill ?? true
    readonly property string priPillColor: cfg.primaryPillColor ?? defaults.primaryPillColor
    readonly property real primarySize: cfg.primarySize ?? defaults.primarySize
    readonly property real primaryBorderRadius: cfg.primaryBorderRadius ?? defaults.primaryBorderRadius ?? 1.0
    readonly property string primaryFocusColor: cfg.primaryFocusColor ?? defaults.primaryFocusColor ?? "primary"

    // Visibility settings
    readonly property bool hideEmpty: cfg.hideEmptyWorkspaces ?? defaults.hideEmptyWorkspaces

    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name)
    readonly property real mainPillSize: Math.round(capsuleHeight * primarySize / 2) * 2
    readonly property real mainIconSize: Style.toOdd(mainPillSize * 0.55)
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

    // --- State tracking ---

    readonly property var activeWorkspaceNames: pluginApi?.mainInstance?.activeWorkspaceNames || ({})
    readonly property string internalActiveSpecial: pluginApi?.mainInstance?.activeSpecialByMonitor?.[screen?.name] ?? ""

    readonly property bool hasActiveWorkspaces: Object.keys(activeWorkspaceNames).length > 0
    readonly property bool isOnSpecial: internalActiveSpecial !== ""
    property bool manuallyExpanded: false
    readonly property bool expanded: isOnSpecial || manuallyExpanded

    onIsOnSpecialChanged: {
        if (!isOnSpecial) {
            manuallyExpanded = false;
            if (needsPanel && pluginApi && root.screen) {
                pluginApi.closePanel(root.screen);
            }
        } else {
            if (needsPanel && pluginApi && root.screen) {
                if (Hyprland.focusedMonitor?.name === root.screen.name) {
                    pluginApi.openPanel(root.screen, root);
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.i("SpecialWorkspaces", "Widget loaded");
    }

    // --- Sizing ---

    readonly property bool showSecondaryPills: !root.needsPanel && (expanded || !showDrawer)

    readonly property real fullSize: {
        if (!showSecondaryPills) {
            return showDrawer ? mainPillSize : 0;
        }
        var pillsSize = 0;
        var count = 0;
        for (var i = 0; i < configuredWorkspaces.length; i++) {
            var ws = configuredWorkspaces[i];
            if (hideEmpty && activeWorkspaceNames[ws.name] !== true) continue;
            pillsSize += Math.round(capsuleHeight * (ws.size ?? 0.9) / 2) * 2;
            count++;
        }
        if (count > 0) pillsSize += pillSpacing * (count - 1);
        return showDrawer
            ? mainPillSize + (count > 0 ? pillSpacing + pillsSize : 0)
            : pillsSize;
    }

    implicitWidth: isVertical ? capsuleHeight : fullSize
    implicitHeight: isVertical ? fullSize : capsuleHeight

    Behavior on implicitWidth { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic } }

    opacity: hasActiveWorkspaces ? 1.0 : 0.3
    Behavior on opacity { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.InOutQuad } }

    clip: false

    // --- Components ---

    component MainButton: Rectangle {
        id: mainBtn
        readonly property bool hasPill: root.priShowPill

        implicitWidth: root.mainPillSize
        implicitHeight: root.mainPillSize
        radius: root.mainPillSize / 2 * root.primaryBorderRadius
        visible: root.showDrawer
        color: {
            if (mainBtnMouse.containsMouse) return hasPill ? Color.mHover : Color.mTertiary;
            if (root.expanded) {
                if (root.primaryFocusColor === "none") return Color.mOnSurface;
                return Color.resolveColorKey(root.primaryFocusColor);
            }
            if (!hasPill) return "transparent";
            if (root.priPillColor === "none") return Color.mOnSurface;
            return Color.resolveColorKey(root.priPillColor);
        }

        Behavior on color { ColorAnimation { duration: Style.animationFast } }

        NIcon {
            icon: root.mainIcon
            pointSize: root.mainIconSize
            applyUiScale: false
            color: {
                if (mainBtnMouse.containsMouse) return mainBtn.hasPill ? Color.mOnHover : Color.mOnTertiary;
                if (root.priSymbolColor !== "none") return Color.resolveColorKey(root.priSymbolColor);
                if (root.expanded) {
                    if (root.primaryFocusColor === "none") return Color.mSurface;
                    return Color.resolveOnColorKey(root.primaryFocusColor);
                }
                if (mainBtn.hasPill) {
                    if (root.priPillColor === "none") return Color.mSurface;
                    return Color.resolveOnColorKey(root.priPillColor);
                }
                return Color.mOnSurface;
            }
            anchors.centerIn: parent
        }

        MouseArea {
            id: mainBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    PanelService.showContextMenu(contextMenu, root, screen);
                    return;
                }

                if (root.needsPanel) {
                    if (pluginApi) pluginApi.togglePanel(root.screen, root);
                    return;
                }

                if (root.expanded) {
                    if (root.isOnSpecial) {
                        Hyprland.dispatch("togglespecialworkspace");
                    }
                    root.manuallyExpanded = false;
                } else {
                    root.manuallyExpanded = true;
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    PanelService.showContextMenu(contextMenu, root, screen);
                    return;
                }
                Hyprland.dispatch(`togglespecialworkspace ${wsPill.modelData.shortName}`);
            }
        }

        Behavior on opacity { NumberAnimation { duration: Style.animationFast } }
    }

    // --- Context Menu ---

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("menu.settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]

        onTriggered: function (action) {
            contextMenu.close();
            PanelService.closeContextMenu(screen);

            if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }

    // --- Layouts ---

    RowLayout {
        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: root.pillSpacing
        layoutDirection: root.expandDirection === "left" ? Qt.RightToLeft : Qt.LeftToRight
        MainButton { Layout.alignment: Qt.AlignVCenter }
        Repeater {
            model: root.configuredWorkspaces
            WorkspacePill {
                visible: (!root.needsPanel && (!root.showDrawer || root.expanded)) && (!root.hideEmpty || root.activeWorkspaceNames[modelData.name] === true)
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
                visible: (!root.needsPanel && (!root.showDrawer || root.expanded)) && root.expandDirection === "up" && (!root.hideEmpty || root.activeWorkspaceNames[modelData.name] === true)
                Layout.alignment: Qt.AlignHCenter
            }
        }
        MainButton { Layout.alignment: Qt.AlignHCenter }
        Repeater {
            model: root.configuredWorkspaces
            WorkspacePill {
                visible: (!root.needsPanel && (!root.showDrawer || root.expanded)) && root.expandDirection === "down" && (!root.hideEmpty || root.activeWorkspaceNames[modelData.name] === true)
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
