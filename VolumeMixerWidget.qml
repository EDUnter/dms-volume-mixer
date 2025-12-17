import QtQuick
import qs.Widgets
import qs.Modules.Plugins
import qs.Common

PluginComponent {
    id: root

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: VolumeMixerService.widgetIcon
                size: Theme.iconSize - 6
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: VolumeMixerService.widgetIcon
                size: Theme.iconSize - 6
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn

            headerText: "Volume Mixer"
            showCloseButton: true

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popoutColumn.headerHeight - popoutColumn.detailsHeight - Theme.spacingXL

                VolumeMixerPopoutContent {
                    width: parent.width
                    height: parent.height - Theme.spacingS * 2
                    anchors.topMargin: Theme.spacingXS
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                }
            }
        }
    }

    popoutWidth: 500
    popoutHeight: 620
}
