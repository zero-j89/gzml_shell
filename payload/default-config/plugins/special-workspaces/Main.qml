import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Services.Compositor

Item {
    id: root
    property var pluginApi: null

    property var activeWorkspaceNames: ({})
    property var activeSpecialByMonitor: ({})

    function updateActiveWorkspaces() {
        if (!CompositorService.isHyprland) {
            activeWorkspaceNames = {};
            return;
        }
        try {
            var names = {};
            var ws = Hyprland.workspaces.values;
            for (var i = 0; i < ws.length; i++) {
                if (ws[i].name && ws[i].name.startsWith("special:")) {
                    names[ws[i].name] = true;
                }
            }
            activeWorkspaceNames = names;
        } catch (e) {
            Logger.w("SpecialWorkspaces", "Failed to update active workspaces: " + e);
            activeWorkspaceNames = {};
        }
    }

    Connections {
        target: CompositorService.isHyprland ? Hyprland : null
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                const dataParts = event.data.split(",");
                const wsName = dataParts[0];
                const monitorName = dataParts[1] ?? "";
                var updated = Object.assign({}, root.activeSpecialByMonitor);
                if (wsName && wsName.startsWith("special:")) {
                    updated[monitorName] = wsName;
                } else {
                    delete updated[monitorName];
                }
                root.activeSpecialByMonitor = updated;
            }
            if (["createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2"].includes(event.name)) {
                updateActiveWorkspaces();
            }
        }
    }

    Component.onCompleted: {
        Logger.i("SpecialWorkspaces", "Main loaded");
        if (CompositorService.isHyprland) {
            updateActiveWorkspaces();
            try {
                var monitors = Hyprland.monitors.values;
                var initial = {};
                for (var i = 0; i < monitors.length; i++) {
                    var m = monitors[i];
                    var wsName = m.specialWorkspace?.name;
                    if (wsName && wsName.startsWith("special:")) {
                        initial[m.name] = wsName;
                    }
                }
                root.activeSpecialByMonitor = initial;
            } catch(e) {
                Logger.w("SpecialWorkspaces", "Failed to read initial special workspaces: " + e);
            }
        }
    }
}
