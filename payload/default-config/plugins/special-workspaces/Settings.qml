import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string mainIcon: cfg.mainIcon ?? defaults.mainIcon
    property string expandDirection: cfg.expandDirection ?? defaults.expandDirection
    property bool   drawer: cfg.drawer ?? defaults.drawer
    property bool   hideEmpty: cfg.hideEmptyWorkspaces ?? defaults.hideEmptyWorkspaces

    property string primarySymbolColor: cfg.primarySymbolColor ?? defaults.primarySymbolColor
    property bool primaryShowPill: cfg.primaryShowPill ?? defaults.primaryShowPill ?? true
    property string primaryPillColor: cfg.primaryPillColor ?? defaults.primaryPillColor
    property real primarySize: cfg.primarySize ?? defaults.primarySize
    property real primaryBorderRadius: cfg.primaryBorderRadius ?? defaults.primaryBorderRadius ?? 1.0
    property string primaryFocusColor: cfg.primaryFocusColor ?? defaults.primaryFocusColor ?? "primary"

    property string panelBackgroundColor: cfg.panelBackgroundColor ?? defaults.panelBackgroundColor ?? "none"
    property bool panelBackgroundEnabled: cfg.panelBackgroundEnabled ?? defaults.panelBackgroundEnabled ?? true

    readonly property string barPosition: Settings.getBarPositionForScreen()
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property bool isPerpendicular: (isBarVertical && (root.expandDirection === "left" || root.expandDirection === "right")) ||
                                            (!isBarVertical && (root.expandDirection === "up" || root.expandDirection === "down"))

    // Local mutable copy for editing
    property var workspaces: []
    property int workspacesRevision: 0

    // Track which workspace rows are expanded
    property var expandedIndices: ({})
    // Track showPill state per workspace (QML-trackable)
    property var showPillStates: ({})

    spacing: Style.marginL

    Component.onCompleted: {
        loadWorkspaces();
    }

    function loadWorkspaces() {
        var src = cfg.workspaces ?? defaults.workspaces;
        if (!src || !Array.isArray(src)) src = [];
        var copy = [];
        for (var i = 0; i < src.length; i++) {
            copy.push({
                "name": src[i].name || "",
                "icon": src[i].icon || "star",
                "symbolColor": src[i].symbolColor ?? "none",
                "showPill": src[i].showPill ?? true,
                "pillColor": src[i].pillColor ?? "primary",
                "size": src[i].size ?? 0.9,
                "borderRadius": src[i].borderRadius ?? 1.0,
                "focusColor": src[i].focusColor ?? "primary"
            });
        }
        var pills = {};
        for (var j = 0; j < copy.length; j++) {
            pills[j] = copy[j].showPill;
        }
        workspaces = copy;
        showPillStates = pills;
        workspacesRevision++;
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("SpecialWorkspaces", "Cannot save settings: pluginApi is null");
            return;
        }

        var valid = [];
        for (var i = 0; i < workspaces.length; i++) {
            var name = workspaces[i].name.trim();
            if (name !== "") {
                valid.push({
                    "name": name,
                    "icon": workspaces[i].icon || "star",
                    "symbolColor": workspaces[i].symbolColor ?? "none",
                    "showPill": workspaces[i].showPill ?? true,
                    "pillColor": workspaces[i].pillColor ?? "primary",
                    "size": workspaces[i].size ?? 0.9,
                    "borderRadius": workspaces[i].borderRadius ?? 1.0,
                    "focusColor": workspaces[i].focusColor ?? "primary"
                });
            }
        }

        pluginApi.pluginSettings.mainIcon = root.mainIcon;
        pluginApi.pluginSettings.expandDirection = root.expandDirection;
        pluginApi.pluginSettings.drawer = root.drawer;
        pluginApi.pluginSettings.hideEmptyWorkspaces = root.hideEmpty;
        pluginApi.pluginSettings.primarySymbolColor = root.primarySymbolColor;
        pluginApi.pluginSettings.primaryShowPill = root.primaryShowPill;
        pluginApi.pluginSettings.primaryPillColor = root.primaryPillColor;
        pluginApi.pluginSettings.primarySize = root.primarySize;
        pluginApi.pluginSettings.primaryBorderRadius = root.primaryBorderRadius;
        pluginApi.pluginSettings.primaryFocusColor = root.primaryFocusColor;
        pluginApi.pluginSettings.panelBackgroundColor = root.panelBackgroundColor;
        pluginApi.pluginSettings.panelBackgroundEnabled = root.panelBackgroundEnabled;
        pluginApi.pluginSettings.workspaces = valid;
        pluginApi.saveSettings();
        Logger.i("SpecialWorkspaces", "Settings saved");
    }

    // ── Title ──

    NText {
        text: pluginApi?.tr("settings.title")
        pointSize: Style.fontSizeL
        font.bold: true
    }

    NText {
        text: pluginApi?.tr("settings.description")
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }

    // ── Drawer Section ──

    NText {
        text: pluginApi?.tr("settings.drawer.title")
        pointSize: Style.fontSizeM
        font.bold: true
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.label")
        description: pluginApi?.tr("settings.drawer.tooltip")
        checked: root.drawer
        onToggled: checked => root.drawer = checked
    }

    RowLayout {
        visible: root.drawer
        spacing: Style.marginM

        NIcon {
            Layout.alignment: Qt.AlignVCenter
            icon: root.mainIcon
            pointSize: Style.fontSizeXL
        }

        NTextInput {
            id: mainIconInput
            Layout.preferredWidth: 140
            label: pluginApi?.tr("settings.drawer.mainIcon.label")
            text: root.mainIcon
            onTextChanged: {
                if (text !== root.mainIcon) {
                    root.mainIcon = text;
                }
            }
        }

        NIconButton {
            icon: "search"
            tooltipText: pluginApi?.tr("settings.drawer.mainIcon.browseTooltip")
            onClicked: {
                mainIconPicker.open();
            }
        }
    }

    NIconPicker {
        id: mainIconPicker
        initialIcon: root.mainIcon
        onIconSelected: function (iconName) {
            root.mainIcon = iconName;
            mainIconInput.text = iconName;
        }
    }

    NColorChoice {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.symbolColor.label")
        description: pluginApi?.tr("settings.drawer.symbolColor.description")
        currentKey: root.primarySymbolColor
        onSelected: key => { root.primarySymbolColor = key; }
        defaultValue: "none"
    }

    NToggle {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.showPill.label")
        description: pluginApi?.tr("settings.drawer.showPill.description")
        checked: root.primaryShowPill
        onToggled: checked => { root.primaryShowPill = checked; }
        defaultValue: true
    }

    NColorChoice {
        visible: root.drawer && root.primaryShowPill
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.pillColor.label")
        description: pluginApi?.tr("settings.drawer.pillColor.description")
        currentKey: root.primaryPillColor
        onSelected: key => { root.primaryPillColor = key; }
        defaultValue: "none"
    }

    NColorChoice {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.focusColor.label")
        description: pluginApi?.tr("settings.drawer.focusColor.description")
        currentKey: root.primaryFocusColor
        onSelected: key => { root.primaryFocusColor = key; }
        defaultValue: "primary"
    }

    ColumnLayout {
        visible: root.drawer
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.drawer.borderRadius.label")
            description: pluginApi?.tr("settings.drawer.borderRadius.description", { value: Math.round(root.primaryBorderRadius * 100) })
        }

        NSlider {
            Layout.fillWidth: true
            from: 0
            to: 1.0
            stepSize: 0.05
            value: root.primaryBorderRadius
            onMoved: root.primaryBorderRadius = value
        }
    }

    ColumnLayout {
        visible: root.drawer
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.drawer.size.label")
            description: pluginApi?.tr("settings.drawer.size.description", { value: Math.round(root.primarySize * 100) })
        }

        NSlider {
            Layout.fillWidth: true
            from: 0.3
            to: 1.0
            stepSize: 0.05
            value: root.primarySize
            onMoved: root.primarySize = value
        }
    }

    NComboBox {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.expandDirection.label")
        description: pluginApi?.tr("settings.drawer.expandDirection.description")
        model: [
            { "key": "down", "name": pluginApi?.tr("settings.drawer.expandDirection.down") },
            { "key": "up", "name": pluginApi?.tr("settings.drawer.expandDirection.up") },
            { "key": "right", "name": pluginApi?.tr("settings.drawer.expandDirection.right") },
            { "key": "left", "name": pluginApi?.tr("settings.drawer.expandDirection.left") }
        ]
        currentKey: root.expandDirection
        onSelected: function (key) {
            root.expandDirection = key;
        }
        defaultValue: "down"
    }

    NToggle {
        visible: root.drawer && root.isPerpendicular
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.panelBackground.enabled.label")
        description: pluginApi?.tr("settings.drawer.panelBackground.enabled.description")
        checked: root.panelBackgroundEnabled
        onToggled: checked => { root.panelBackgroundEnabled = checked; }
        defaultValue: true
    }

    NColorChoice {
        visible: root.drawer && root.isPerpendicular && root.panelBackgroundEnabled
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.panelBackgroundColor.label")
        description: pluginApi?.tr("settings.drawer.panelBackgroundColor.description")
        currentKey: root.panelBackgroundColor
        onSelected: key => { root.panelBackgroundColor = key; }
        defaultValue: "none"
    }

    // ── Workspaces Section ──

    NDivider {
        Layout.fillWidth: true
    }

    NText {
        text: pluginApi?.tr("settings.workspaces.title")
        pointSize: Style.fontSizeM
        font.bold: true
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.workspaces.hideEmpty.label")
        description: pluginApi?.tr("settings.workspaces.hideEmpty.description")
        checked: root.hideEmpty
        onToggled: checked => root.hideEmpty = checked
    }

    // Workspace list
    Repeater {
        model: {
            void root.workspacesRevision;
            return root.workspaces.length;
        }

        delegate: ColumnLayout {
            id: wsRow
            required property int index

            Layout.fillWidth: true
            spacing: Style.marginS

            readonly property var ws: {
                void root.workspacesRevision;
                return index >= 0 && index < root.workspaces.length ? root.workspaces[index] : null;
            }

            readonly property bool wsExpanded: root.expandedIndices[index] === true

            // ── Collapsed row (always visible) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NIcon {
                    Layout.alignment: Qt.AlignVCenter
                    icon: wsRow.ws ? wsRow.ws.icon : "star"
                    pointSize: Style.fontSizeXL
                }

                NTextInput {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 140
                    placeholderText: pluginApi?.tr("settings.workspaces.namePlaceholder")
                    text: wsRow.ws ? wsRow.ws.name : ""
                    onTextChanged: {
                        if (wsRow.ws && text !== wsRow.ws.name) {
                            root.workspaces[wsRow.index].name = text;
                        }
                    }
                }

                NTextInput {
                    id: iconInput
                    Layout.preferredWidth: 120
                    placeholderText: pluginApi?.tr("settings.workspaces.iconPlaceholder")
                    text: wsRow.ws ? wsRow.ws.icon : ""
                    onTextChanged: {
                        if (wsRow.ws && text !== wsRow.ws.icon) {
                            root.workspaces[wsRow.index].icon = text;
                            root.workspacesRevision++;
                        }
                    }

                    Connections {
                        target: root
                        function onWorkspacesRevisionChanged() {
                            if (wsRow.ws && iconInput.text !== wsRow.ws.icon) {
                                iconInput.text = wsRow.ws.icon;
                            }
                        }
                    }
                }

                NIconButton {
                    icon: "search"
                    tooltipText: pluginApi?.tr("settings.workspaces.browseTooltip")
                    onClicked: {
                        iconPicker.activeIndex = wsRow.index;
                        iconPicker.initialIcon = wsRow.ws ? wsRow.ws.icon : "star";
                        iconPicker.query = wsRow.ws ? wsRow.ws.icon : "";
                        iconPicker.open();
                    }
                }

                NIconButton {
                    icon: wsRow.wsExpanded ? "chevron-up" : "chevron-down"
                    tooltipText: pluginApi?.tr("settings.workspaces.expandTooltip")
                    onClicked: {
                        var copy = Object.assign({}, root.expandedIndices);
                        copy[wsRow.index] = !wsRow.wsExpanded;
                        root.expandedIndices = copy;
                    }
                }

                NIconButton {
                    icon: "trash"
                    tooltipText: pluginApi?.tr("settings.workspaces.removeTooltip")
                    onClicked: {
                        var copy = Object.assign({}, root.expandedIndices);
                        delete copy[wsRow.index];
                        root.expandedIndices = copy;
                        root.workspaces.splice(wsRow.index, 1);
                        root.workspacesRevision++;
                    }
                }
            }

            // ── Expanded section (per-workspace styling) ──
            ColumnLayout {
                visible: wsRow.wsExpanded
                Layout.fillWidth: true
                Layout.leftMargin: Style.marginL
                spacing: Style.marginM

                NColorChoice {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("settings.workspaces.symbolColor.label")
                    description: pluginApi?.tr("settings.workspaces.symbolColor.description")
                    currentKey: wsRow.ws ? wsRow.ws.symbolColor ?? "none" : "none"
                    onSelected: key => {
                        root.workspaces[wsRow.index].symbolColor = key;
                        root.workspacesRevision++;
                    }
                    defaultValue: "none"
                }

                NToggle {
                    id: showPillToggle
                    Layout.fillWidth: true
                    label: pluginApi?.tr("settings.workspaces.showPill.label")
                    description: pluginApi?.tr("settings.workspaces.showPill.description")
                    checked: root.showPillStates[wsRow.index] ?? true
                    onToggled: checked => {
                        root.workspaces[wsRow.index].showPill = checked;
                        var copy = Object.assign({}, root.showPillStates);
                        copy[wsRow.index] = checked;
                        root.showPillStates = copy;
                    }
                    defaultValue: true
                }

                NColorChoice {
                    visible: root.showPillStates[wsRow.index] ?? true
                    Layout.fillWidth: true
                    label: pluginApi?.tr("settings.workspaces.pillColor.label")
                    description: pluginApi?.tr("settings.workspaces.pillColor.description")
                    currentKey: wsRow.ws ? wsRow.ws.pillColor ?? "primary" : "primary"
                    onSelected: key => {
                        root.workspaces[wsRow.index].pillColor = key;
                        root.workspacesRevision++;
                    }
                    defaultValue: "primary"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NLabel {
                        label: pluginApi?.tr("settings.workspaces.size.label")
                        description: pluginApi?.tr("settings.workspaces.size.description", { value: Math.round((wsRow.ws ? wsRow.ws.size ?? 0.9 : 0.9) * 100) })
                    }

                    NSlider {
                        Layout.fillWidth: true
                        from: 0.3
                        to: 1.0
                        stepSize: 0.05
                        value: wsRow.ws ? wsRow.ws.size ?? 0.9 : 0.9
                        onMoved: {
                            root.workspaces[wsRow.index].size = value;
                            root.workspacesRevision++;
                        }
                    }
                }

                NColorChoice {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("settings.workspaces.focusColor.label")
                    description: pluginApi?.tr("settings.workspaces.focusColor.description")
                    currentKey: wsRow.ws ? wsRow.ws.focusColor ?? "primary" : "primary"
                    onSelected: key => {
                        root.workspaces[wsRow.index].focusColor = key;
                        root.workspacesRevision++;
                    }
                    defaultValue: "primary"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NLabel {
                        label: pluginApi?.tr("settings.workspaces.borderRadius.label")
                        description: pluginApi?.tr("settings.workspaces.borderRadius.description", { value: Math.round((wsRow.ws ? wsRow.ws.borderRadius ?? 1.0 : 1.0) * 100) })
                    }

                    NSlider {
                        Layout.fillWidth: true
                        from: 0
                        to: 1.0
                        stepSize: 0.05
                        value: wsRow.ws ? wsRow.ws.borderRadius ?? 1.0 : 1.0
                        onMoved: {
                            root.workspaces[wsRow.index].borderRadius = value;
                            root.workspacesRevision++;
                        }
                    }
                }
            }
        }
    }

    NIconPicker {
        id: iconPicker
        property int activeIndex: -1
        initialIcon: "star"
        onIconSelected: function (iconName) {
            if (activeIndex >= 0 && activeIndex < root.workspaces.length) {
                root.workspaces[activeIndex].icon = iconName;
                root.workspacesRevision++;
            }
        }
    }

    NButton {
        text: pluginApi?.tr("settings.workspaces.add")
        icon: "plus"
        onClicked: {
            root.workspaces.push({
                "name": "",
                "icon": "star",
                "symbolColor": "none",
                "showPill": true,
                "pillColor": "primary",
                "size": 0.9,
                "borderRadius": 1.0,
                "focusColor": "primary"
            });
            var pills = Object.assign({}, root.showPillStates);
            pills[root.workspaces.length - 1] = true;
            root.showPillStates = pills;
            root.workspacesRevision++;
        }
    }
}
