import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import Quickshell.Widgets
import "IconLookupMap.js" as IconLookupMap

DankFlickable {
    id: root

    Component.onCompleted: {
        if (AudioService.soundsAvailable && AudioService.mediaDevices !== null) {
            if (VolumeMixerService.savedNotificationsVolume === -1) {
                VolumeMixerService.savedNotificationsVolume = AudioService.notificationsVolume;
                VolumeMixerService.saveNotificationsVolume(VolumeMixerService.savedNotificationsVolume);
            } else {
                AudioService.notificationsVolume = VolumeMixerService.savedNotificationsVolume;
            }
        }
    }

    anchors.fill: parent
    clip: true
    contentHeight: rootColumn.implicitHeight + Theme.spacingS * 2

    Column {
        id: rootColumn

        anchors.fill: parent
        anchors.topMargin: Theme.spacingM
        anchors.bottomMargin: Theme.spacingL
        spacing: Theme.spacingM

        // System Volume Section
        Row {
            StyledText {
                text: I18n.tr("System")
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledRect {
            width: parent.width
            height: systemAudioSection.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 0

            Column {
                id: systemAudioSection
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                //Main Volume Section
                Row {
                    width: parent.width
                    height: Theme.iconSize - 4 + Theme.spacingS
                    spacing: Theme.spacingXS

                    DankIcon {
                        name: "media_output"
                        size: Theme.iconSize - 4 + Theme.spacingS
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: I18n.tr("Volume")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    width: parent.width
                    height: Theme.iconSize - 4 + Theme.spacingS
                    spacing: Theme.spacingXS

                    Rectangle {
                        width: Theme.iconSize - 4 + Theme.spacingS
                        height: Theme.iconSize - 4 + Theme.spacingS
                        radius: (Theme.iconSize - 4 + Theme.spacingS) / 2
                        color: systemVolumeIconArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.withAlpha(Theme.primary, 0)
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: systemVolumeIconArea
                            anchors.fill: parent
                            visible: AudioService.sink !== null
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (AudioService.sink) {
                                    AudioService.suppressOSD = true;
                                    AudioService.sink.audio.muted = !AudioService.sink.audio.muted;
                                    AudioService.suppressOSD = false;
                                }
                            }
                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: {
                                if (!AudioService.sink)
                                    return "volume_off";

                                let volume = AudioService.sink.audio.volume;
                                let muted = AudioService.sink.audio.muted;

                                if (muted || volume === 0.0)
                                    return "volume_off";
                                if (volume <= 0.33)
                                    return "volume_down";
                                if (volume <= 0.66)
                                    return "volume_up";
                                return "volume_up";
                            }
                            size: Theme.iconSize - 2
                            color: Theme.primary
                        }
                    }

                    StyledText {
                        text: AudioService.sink ? I18n.tr(Math.round(AudioService.sink.audio.volume * 100)) : "0%"
                        width: 28
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    CustomDankSlider {
                        readonly property real actualVolumePercent: AudioService.sink ? Math.round(AudioService.sink.audio.volume * 100) : 0
                        width: parent.width - (28 + Theme.iconSize + Theme.spacingS * 2)
                        trackHeight: 5
                        enabled: AudioService.sink !== null
                        minimum: 0
                        maximum: 100
                        value: AudioService.sink ? Math.min(100, Math.round(AudioService.sink.audio.volume * 100)) : 0
                        showValue: true
                        unit: "%"
                        wheelEnabled: false
                        valueOverride: actualVolumePercent
                        thumbOutlineColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                        anchors.verticalCenter: parent.verticalCenter
                        onIsDraggingChanged: {
                            if (isDragging) {
                                AudioService.suppressOSD = true;
                            } else {
                                Qt.callLater(() => {
                                    AudioService.suppressOSD = false;
                                });
                            }
                        }
                        onSliderValueChanged: function (newValue) {
                            if (AudioService.sink) {
                                AudioService.sink.audio.volume = newValue / 100.0;
                                if (newValue > 0 && AudioService.sink.audio.muted) {
                                    AudioService.sink.audio.muted = false;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outline
                    opacity: 0.2
                    visible: typeof AudioService.notificationsVolume !== 'undefined'
                }

                // Notifications Volume Section
                Row {
                    width: parent.width
                    height: Theme.iconSize - 4 + Theme.spacingS
                    spacing: Theme.spacingXS
                    visible: typeof AudioService.notificationsVolume !== 'undefined'

                    DankIcon {
                        name: "notification_sound"
                        size: Theme.iconSize - 4 + Theme.spacingS
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: I18n.tr("Notifications Volume")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    width: parent.width
                    height: Theme.iconSize - 4 + Theme.spacingS
                    spacing: Theme.spacingXS
                    visible: typeof AudioService.notificationsVolume !== 'undefined'

                    Rectangle {
                        width: Theme.iconSize - 4 + Theme.spacingS
                        height: Theme.iconSize - 4 + Theme.spacingS
                        radius: (Theme.iconSize - 4 + Theme.spacingS) / 2
                        color: notificationsVolumeIconArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.withAlpha(Theme.primary, 0)
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: notificationsVolumeIconArea
                            anchors.fill: parent
                            visible: AudioService.soundsAvailable && AudioService.mediaDevices !== null
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (AudioService.notificationsVolume) {
                                    AudioService.notificationsAudioMuted = !AudioService.notificationsAudioMuted;
                                    if (!AudioService.notificationsAudioMuted) {
                                        AudioService.playNormalNotificationSound();
                                    }
                                }
                            }
                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: {
                                if (!(AudioService.soundsAvailable && AudioService.mediaDevices !== null))
                                    return "volume_off";

                                let volume = AudioService.notificationsVolume;
                                let muted = AudioService.notificationsAudioMuted;

                                if (muted || volume === 0.0)
                                    return "volume_off";
                                if (volume <= 0.33)
                                    return "volume_down";
                                if (volume <= 0.66)
                                    return "volume_up";
                                return "volume_up";
                            }
                            size: Theme.iconSize - 2
                            color: Theme.primary
                        }
                    }

                    StyledText {
                        text: AudioService.soundsAvailable && AudioService.mediaDevices !== null ? I18n.tr(Math.round(AudioService.notificationsVolume * 100)) : "0"
                        width: 28
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    CustomDankSlider {
                        readonly property real actualVolumePercent: AudioService.soundsAvailable && AudioService.mediaDevices !== null ? Math.round(AudioService.notificationsVolume * 100) : 0
                        width: parent.width - (28 + Theme.iconSize + Theme.spacingS * 2)
                        trackHeight: 5
                        enabled: AudioService.soundsAvailable && AudioService.mediaDevices !== null
                        minimum: 0
                        maximum: 100
                        value: AudioService.soundsAvailable && AudioService.mediaDevices !== null ? Math.min(100, Math.round(AudioService.notificationsVolume * 100)) : 0
                        showValue: true
                        unit: "%"
                        wheelEnabled: false
                        valueOverride: actualVolumePercent
                        thumbOutlineColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                        anchors.verticalCenter: parent.verticalCenter
                        onSliderValueChanged: function (newValue) {
                            if (AudioService.soundsAvailable && AudioService.mediaDevices !== null) {
                                const newVolume = newValue / 100.0;
                                AudioService.notificationsVolume = newVolume;

                                VolumeMixerService.saveNotificationsVolume(newVolume);

                                if (newValue > 0 && AudioService.notificationsAudioMuted) {
                                    AudioService.notificationsAudioMuted = false;
                                }
                                AudioService.playNormalNotificationSound();
                            }
                        }
                    }
                }
            }
        }

        //Apps Volume Section
        Row {
            visible: Object.keys(VolumeMixerService.sourceNodesByApp).length > 0
            StyledText {
                text: I18n.tr("Apps")
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledRect {
            width: parent.width
            height: appAudioSection.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 0
            visible: Object.keys(VolumeMixerService.sourceNodesByApp).length > 0

            Column {
                id: appAudioSection
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                Repeater {
                    model: Object.keys(VolumeMixerService.sourceNodesByApp)

                    delegate: Column {
                        id: audioAppRoot
                        width: parent.width
                        spacing: Theme.spacingS

                        required property int index
                        required property var modelData
                        property string appId: modelData
                        property var sourceNodes: Object.values(VolumeMixerService.sourceNodesByApp[appId].nodesById)
                        property PwNode sourceNode: sourceNodes[0].node
                        property string appIconId: sourceNode.properties["pipewire.access.portal.app_id"] || sourceNode.properties["application.process.binary"] || sourceNode.name
                        property bool iconFound: true
                        property string appProcess: sourceNode.properties["application.process.binary"] || null
                        property string friendlyGroupName: VolumeMixerService.getFriendlyGroupName(appProcess, appId)

                        Row {
                            id: rowItemTextIcon
                            width: parent.width
                            height: appIcon.height - 4 + Theme.spacingS
                            spacing: Theme.spacingXS

                            IconImage {
                                id: appIcon
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconSize - 4 + Theme.spacingS
                                height: Theme.iconSize - 4 + Theme.spacingS
                                source: {
                                    let moddedId = Paths.moddedAppId(audioAppRoot.appIconId);

                                    if (moddedId === "") {
                                        return;
                                    }

                                    const mappedId = IconLookupMap.get(moddedId);
                                    if (mappedId) {
                                        return Quickshell.iconPath(DesktopEntries.heuristicLookup(mappedId)?.icon, true);
                                    }

                                    const icon = DesktopEntries.heuristicLookup(moddedId)?.icon;
                                    if (!icon) {
                                        audioAppRoot.iconFound = false;
                                    }

                                    return Quickshell.iconPath(icon, true);
                                }
                                smooth: true
                                mipmap: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            DankIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                size: Theme.iconSize - 4 + Theme.spacingS
                                name: "disc_full"
                                color: Theme.surfaceText
                                visible: !iconFound
                            }

                            Item {
                                height: parent.height
                                width: parent.width - (Theme.iconSize + Theme.spacingL)
                                StyledText {
                                    text: I18n.tr(audioAppRoot.friendlyGroupName)
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Row {
                            id: rowAppSlider
                            width: parent.width
                            height: Theme.iconSize + Theme.spacingS
                            spacing: Theme.spacingXS

                            Rectangle {
                                width: Theme.iconSize - 4 + Theme.spacingS
                                height: Theme.iconSize - 4 + Theme.spacingS
                                radius: (Theme.iconSize - 4 + Theme.spacingS) / 2
                                color: appIconArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.withAlpha(Theme.primary, 0)
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    id: appIconArea
                                    anchors.fill: parent
                                    visible: audioAppRoot.sourceNode !== null
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const targetMuteState = !audioAppRoot.sourceNode.audio.muted;

                                        for (let i = 0; i < audioAppRoot.sourceNodes.length; i++) {
                                            const nodeToMute = audioAppRoot.sourceNodes[i].node;
                                            if (nodeToMute) {
                                                nodeToMute.audio.muted = targetMuteState;
                                            }
                                        }
                                    }
                                }

                                DankIcon {
                                    id: audioIcon
                                    anchors.centerIn: parent
                                    name: {
                                        if (!audioAppRoot.sourceNode)
                                            return "volume_off";

                                        if (VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] === undefined) {
                                            VolumeMixerService.saveVolumeFactor(audioAppRoot.friendlyGroupName, 1);
                                        }

                                        const volume = audioAppRoot.sourceNode && VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] ? VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] : 0;
                                        const muted = audioAppRoot.sourceNode.audio.muted;

                                        if (muted || volume === 0.0)
                                            return "volume_off";
                                        if (volume <= 0.33)
                                            return "volume_down";
                                        if (volume <= 0.66)
                                            return "volume_up";
                                        return "volume_up";
                                    }
                                    size: Theme.iconSize - 2
                                    color: Theme.primary
                                }
                            }

                            StyledText {
                                id: appVolumeText
                                text: audioAppRoot.sourceNode && VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] ? Math.round(VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] * 100) : 0
                                width: 28
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            CustomDankSlider {
                                id: appSlider
                                width: parent.width - (28 + Theme.iconSize + Theme.spacingS * 2)
                                trackHeight: 5
                                enabled: audioAppRoot.sourceNode !== null
                                minimum: 0
                                maximum: 100
                                value: audioAppRoot.sourceNode && VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] ? VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] * 100 : 0
                                showValue: true
                                unit: "%"
                                wheelEnabled: false
                                valueOverride: audioAppRoot.sourceNode && VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] ? VolumeMixerService.savedAppVolumeFactors[audioAppRoot.friendlyGroupName] * 100 : 0
                                thumbOutlineColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: function (newValue) {
                                    appSlider.valueOverride = newValue;
                                    appVolumeText.text = newValue;

                                    let icon = "";

                                    if (newValue >= 33) {
                                        icon = "volume_up";
                                    } else if (newValue > 0) {
                                        icon = "volume_down";
                                    } else if (newValue === 0.0) {
                                        icon = "volume_off";
                                    }

                                    audioIcon.name = icon;
                                }
                                onSliderDragFinished: function (finalValue) {
                                    const volumeFactor = finalValue / 100.0;
                                    const appId = audioAppRoot.appId;

                                    const nodesById = VolumeMixerService.sourceNodesByApp[appId].nodesById;
                                    const sourceNodeIds = Object.keys(nodesById);

                                    for (let i = 0; i < sourceNodeIds.length; i++) {
                                        const nodeId = sourceNodeIds[i];

                                        VolumeMixerService.triggerFactorUpdate(nodeId, volumeFactor);

                                        const node = nodesById[nodeId].node;
                                        if (finalValue > 0 && node && node.audio.muted) {
                                            node.audio.muted = false;
                                        }
                                    }

                                    VolumeMixerService.saveVolumeFactor(audioAppRoot.friendlyGroupName, volumeFactor);
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.outline
                            opacity: 0.2
                            visible: audioAppRoot.index < Object.keys(VolumeMixerService.sourceNodesByApp).length - 1
                        }
                    }
                }
            }
        }
    }
}
