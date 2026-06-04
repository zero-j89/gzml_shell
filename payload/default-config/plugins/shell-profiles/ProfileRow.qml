import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

NBox {
  id: root

  property string profileName: ""
  property bool includeWallpapers: true
  property var service: null
  property var pluginApi: null
  property var panelRef: null

  // Computed from service state
  readonly property bool isActive: profileName !== "" && profileName === (service?.lastAppliedProfile ?? "")
  readonly property string savedAtFormatted: {
    var s = service?.profileMeta?.[profileName]?.savedAt ?? "";
    if (!s)
      return "";
    try {
      var d = new Date(s);
      return Qt.formatDate(d, "dd MMM yyyy") + "  " + Qt.formatTime(d, "HH:mm");
    } catch (e) {
      return "";
    }
  }

  Layout.fillWidth: true
  Layout.leftMargin: Style.borderS
  Layout.rightMargin: Style.borderS
  implicitHeight: savedAtFormatted !== "" ? 60 : 48

  // Active profile left accent bar
  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.leftMargin: -Style.borderS
    width: 3
    radius: Style.radiusXS
    color: Color.mPrimary
    visible: root.isActive

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
      }
    }
  }

  // ── Context menu ──────────────────────────────────────────────────────────

  NContextMenu {
    id: contextMenu
    parent: Overlay.overlay
    model: [
      {
        "label": pluginApi?.tr("panel.action-overwrite"),
        "action": "overwrite",
        "icon": "edit"
      },
      {
        "label": pluginApi?.tr("panel.action-rename"),
        "action": "rename",
        "icon": "pencil"
      },
      {
        "label": pluginApi?.tr("panel.action-delete"),
        "action": "delete",
        "icon": "trash"
      }
    ]
    onTriggered: action => {
                   contextMenu.close();
                   if (action === "overwrite") {
                     service?.saveProfile(root.profileName);
                   } else if (action === "rename") {
                     renameInput.text = root.profileName;
                     renameError.text = "";
                     renameDialog.open();
                   } else if (action === "delete") {
                     deleteDialog.open();
                   }
                 }
  }

  // ── Delete confirmation dialog ────────────────────────────────────────────

  Popup {
    id: deleteDialog
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.round(320 * Style.uiScaleRatio)
    padding: Style.marginL
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
      color: Color.mSurface
      radius: Style.radiusM
      border.color: Color.mOutline
      border.width: Style.borderS
    }

    contentItem: ColumnLayout {
      spacing: Style.marginM

      NIcon {
        icon: "trash"
        pointSize: Style.fontSizeXXL * 1.5
        color: Color.mError
        Layout.alignment: Qt.AlignHCenter
      }

      NLabel {
        label: pluginApi?.tr("panel.delete-confirm-title")
        Layout.alignment: Qt.AlignHCenter
      }

      NText {
        text: (pluginApi?.tr("panel.delete-confirm-message")).replace("{name}", root.profileName)
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: Style.marginM
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXS

        NButton {
          text: I18n.tr("common.cancel")
          outlined: true
          Layout.fillWidth: true
          onClicked: deleteDialog.close()
        }

        NButton {
          text: pluginApi?.tr("panel.action-delete")
          backgroundColor: Color.mError
          textColor: Color.mOnError
          Layout.fillWidth: true
          onClicked: {
            deleteDialog.close();
            service?.deleteProfile(root.profileName);
          }
        }
      }
    }
  }

  // ── Rename dialog ─────────────────────────────────────────────────────────

  Popup {
    id: renameDialog
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.round(340 * Style.uiScaleRatio)
    padding: Style.marginL
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
      color: Color.mSurface
      radius: Style.radiusM
      border.color: Color.mOutline
      border.width: Style.borderS
    }

    contentItem: ColumnLayout {
      spacing: Style.marginM

      NLabel {
        label: pluginApi?.tr("panel.rename-title")
      }

      NTextInput {
        id: renameInput
        Layout.fillWidth: true
        placeholderText: pluginApi?.tr("panel.rename-placeholder")
        Keys.onReturnPressed: renameApplyBtn.clicked()
      }

      NText {
        id: renameError
        visible: text !== ""
        color: Color.mError
        pointSize: Style.fontSizeS
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: Style.marginM
        Layout.fillWidth: true

        NButton {
          text: I18n.tr("common.cancel")
          outlined: true
          Layout.fillWidth: true
          onClicked: renameDialog.close()
        }

        NButton {
          id: renameApplyBtn
          text: I18n.tr("common.apply")
          Layout.fillWidth: true
          enabled: renameInput.text.trim() !== "" && renameInput.text.trim() !== root.profileName
          onClicked: {
            var newName = renameInput.text.trim();
            var err = service?.validateName(newName) || "";
            if (err) {
              renameError.text = err;
              return;
            }
            if (service?.profileExists(newName)) {
              renameError.text = pluginApi?.tr("error.name-exists");
              return;
            }
            service?.renameProfile(root.profileName, newName, function (ok, msg) {
              if (ok)
                renameDialog.close();
              else
                renameError.text = msg;
            });
          }
        }
      }
    }
  }

  // ── Row content ────────────────────────────────────────

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Style.marginM
    anchors.rightMargin: Style.marginM
    spacing: Style.marginS

    // Active check icon
    Rectangle {
      id: activeIcon
      width: root.isActive ? Math.round(Style.baseWidgetSize * 0.45) : 0
      height: Math.round(Style.baseWidgetSize * 0.45)
      radius: height / 2
      color: Color.mPrimary
      opacity: root.isActive ? 1 : 0
      visible: root.isActive
      Layout.alignment: Qt.AlignVCenter

      Behavior on width {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }

      NIcon {
        anchors.centerIn: parent
        icon: "check"
        color: Color.mOnPrimary
        pointSize: Style.fontSizeS
      }
    }

    // Profile name + date
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: Style.marginXS

      NText {
        id: nameText
        Layout.fillWidth: true
        text: root.profileName
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightSemiBold
        color: root.isActive ? Color.mPrimary : Color.mOnSurface
        elide: Text.ElideRight

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }
      }

      NText {
        Layout.fillWidth: true
        text: root.savedAtFormatted
        visible: root.savedAtFormatted !== ""
        pointSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        elide: Text.ElideRight
      }
    }

    NButton {
      id: applyBtn
      text: pluginApi?.tr("panel.action-apply")
      icon: "download"
      enabled: !(service?.isBusy ?? false)
      Layout.alignment: Qt.AlignVCenter
      onClicked: {
        service?.applyProfile(root.profileName, root.includeWallpapers);
        if (root.panelRef)
          pluginApi?.closePanel(pluginApi.panelOpenScreen);
      }
    }

    NIconButton {
      id: wallpaperToggle
      icon: "photo"
      tooltipText: pluginApi?.tr("panel.include-wallpapers")
      baseSize: Math.round(Style.fontSizeXXL * Style.uiScaleRatio)
      colorBg: "transparent"
      colorFg: root.includeWallpapers ? Color.mPrimary : Color.mOnSurfaceVariant
      Layout.alignment: Qt.AlignVCenter
      onClicked: root.includeWallpapers = !root.includeWallpapers
    }

    NIconButton {
      id: dotsBtn
      icon: "dots-vertical"
      tooltipText: pluginApi?.tr("panel.more-actions")
      baseSize: Math.round(Style.fontSizeXXL * Style.uiScaleRatio)
      colorBg: "transparent"
      colorFg: Color.mOnSurfaceVariant
      Layout.alignment: Qt.AlignVCenter
      onClicked: contextMenu.openAtItem(this, width / 2, height / 2)
    }
  }
}
