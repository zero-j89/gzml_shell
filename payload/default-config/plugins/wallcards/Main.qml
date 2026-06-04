import QtQuick
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null

  function hide() {
    if (windowLoader.item)
      windowLoader.item.close();
    else
      windowLoader.active = false;
  }
  function show() {
    windowLoader.active = true;
  }
  function toggle() {
    if (windowLoader.active)
      hide();
    else
      show();
  }

  Loader {
    id: windowLoader

    active: false
    source: "Wallcards.qml"

    onLoaded: item.pluginApi = Qt.binding(() => root.pluginApi)

    Connections {
      function onQuitRequested() {
        windowLoader.active = false;
      }

      target: windowLoader.item
    }
  }
  IpcHandler {
    function hide() {
      root.hide();
    }
    function show() {
      root.show();
    }
    function toggle() {
      root.toggle();
    }

    target: "plugin:wallcards"
  }
}
