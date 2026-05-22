import QtQuick
import "../../Modules/Bar/Widgets"

QtObject {
    Component.onCompleted: {
        BarWidgetRegistry.registerPluginWidget(
            "NagaMode",
            Qt.createComponent("../../Modules/Bar/Widgets/NagaMode.qml")
        )
    }
}
