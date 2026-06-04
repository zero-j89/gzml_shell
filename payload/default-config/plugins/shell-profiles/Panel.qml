import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  // Plugin API
  property var pluginApi: null

  // SmartPanel integration
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  // Preferred dimensions
  property real contentPreferredWidth: Math.round(380 * Style.uiScaleRatio)
  property real contentPreferredHeight: Math.round(480 * Style.uiScaleRatio)

  // Shortcut to service
  readonly property var service: pluginApi?.mainInstance

  readonly property bool defaultIncludeWallpapers:
    pluginApi?.pluginSettings?.includeWallpapers ??
    pluginApi?.manifest?.metadata?.defaultSettings?.includeWallpapers ??
    true

  property string searchQuery: ""

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // ── Header ──────────────────────────────────────────────────────────────
      NBox {
        id: headerBox
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: pluginApi?.pluginSettings?.icon || "bookmark"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          NLabel {
            label: pluginApi?.tr("panel.title")
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "settings"
            tooltipText: I18n.tr("tooltips.open-settings")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              var screen = pluginApi?.panelOpenScreen
              if (screen && pluginApi?.manifest)
                BarService.openPluginSettings(screen, pluginApi.manifest)
            }
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: pluginApi?.closePanel(pluginApi.panelOpenScreen)
          }
        }
      }

      // ── Save bar ─────────────────────────────────────────────────────────────
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: saveRow.implicitHeight + Style.margin2M

        RowLayout {
          id: saveRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NTextInput {
            id: saveInput
            Layout.fillWidth: true
            placeholderText: pluginApi?.tr("panel.save-placeholder")
            Keys.onReturnPressed: {
              if (saveBtn.enabled) saveBtn.clicked()
            }
          }

          NButton {
            id: saveBtn
            text: pluginApi?.tr("panel.save-button")
            icon: "bookmark-plus"
            enabled: saveInput.text.trim() !== "" && !(service?.isBusy ?? false)
            onClicked: {
              var name = saveInput.text.trim()
              var err = service?.validateName(name) || ""
              if (err) { saveError.text = err; return }
              service?.saveProfile(name, function(ok, msg) {
                if (ok) {
                  saveInput.text = ""
                  saveError.text = ""
                } else {
                  saveError.text = msg
                }
              })
            }
          }
        }
      }

      NText {
        id: saveError
        visible: text !== ""
        color: Color.mError
        pointSize: Style.fontSizeS
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: Style.marginS
      }

      // ── Search filter ─────────────────────────────────────────────────────────
      NTextInput {
        Layout.fillWidth: true
        placeholderText: pluginApi?.tr("panel.search-placeholder")
        inputIconName: "search"
        visible: (service?.profiles?.length ?? 0) > 0
        onTextChanged: root.searchQuery = text
      }

      // ── Profile list ─────────────────────────────────────────────────────────
      NScrollView {
        id: profileScrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalPolicy: ScrollBar.AlwaysOff
        verticalPolicy: ScrollBar.AsNeeded
        reserveScrollbarSpace: false
        gradientColor: Color.mSurface

        ColumnLayout {
          id: listColumn
          width: profileScrollView.availableWidth
          spacing: Style.marginM

          // Empty state
          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: emptyCol.implicitHeight + Style.margin2XL
            visible: (service?.profiles?.length ?? 0) === 0

            ColumnLayout {
              id: emptyCol
              anchors.centerIn: parent
              spacing: Style.marginM

              NIcon {
                icon: "bookmark-off"
                pointSize: Style.fontSizeXXL * 2
                color: Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
              }

              NText {
                text: pluginApi?.tr("panel.empty")
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.maximumWidth: Math.round(260 * Style.uiScaleRatio)
              }
            }
          }

          // Profile rows
          Repeater {
            model: {
              var all = service?.profiles ?? []
              if (root.searchQuery.trim() === "") return all
              var q = root.searchQuery.toLowerCase()
              return all.filter(function(p) { return p.toLowerCase().indexOf(q) !== -1 })
            }

            delegate: ProfileRow {
              profileName: modelData
              includeWallpapers: root.defaultIncludeWallpapers
              service: root.service
              pluginApi: root.pluginApi
              panelRef: root
              Layout.fillWidth: true
            }
          }
        }
      }
    }
  }

  // Refresh list each time the panel opens
  onVisibleChanged: {
    if (visible)
      service?.listProfiles()
  }
}
