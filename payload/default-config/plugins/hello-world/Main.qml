import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  property var pluginApi: null

  IpcHandler {
    target: "plugin:hello-world"
    function setMessage(message: string) {
      if (pluginApi && message) {
        // Update the plugin settings object
        pluginApi.pluginSettings.message = message;

        // Save to disk
        pluginApi.saveSettings();

        // Show confirmation
        ToastService.showNotice("Message updated to: " + message);
      }
    }
    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen);
        });
      }
    }
  }
}