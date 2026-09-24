import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 4

    property string text: ""
    property string buttonIcon: "palette"
    property string value: ""
    property color defaultColor: Appearance.colors.colPrimary
    property var presets: [Appearance.colors.colPrimary, Appearance.colors.colSecondary, Appearance.colors.colTertiary, Appearance.colors.colOnSurface, "#ffffff", "#000000"]
    property bool expanded: false

    signal picked(string value)

    property real hue: 0
    property real saturation: 0
    property real brightness: 1
    property real alpha: 1
    property string lastPicked: ""
    readonly property color displayColor: value !== "" ? value : defaultColor

    function syncFromValue() {
        if (root.value !== "" && root.value === root.lastPicked)
            return;
        const c = root.displayColor;
        if (c.hsvHue >= 0)
            root.hue = c.hsvHue;
        root.saturation = c.hsvSaturation;
        root.brightness = c.hsvValue;
        root.alpha = c.a;
    }

    function pick(h, s, v) {
        root.hue = h;
        root.saturation = s;
        root.brightness = v;
        root.lastPicked = Qt.hsva(h, s, v, root.alpha).toString();
        root.picked(root.lastPicked);
    }

    function clamp01(x) {
        return Math.max(0, Math.min(1, x));
    }

    onDisplayColorChanged: syncFromValue()
    Component.onCompleted: syncFromValue()

    RippleButton {
        id: header
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + 8 * 2
        font.pixelSize: Appearance.font.pixelSize.small
        onClicked: root.expanded = !root.expanded

        contentItem: RowLayout {
            id: headerRow
            spacing: 10

            OptionalMaterialSymbol {
                icon: root.buttonIcon
                iconSize: Appearance.font.pixelSize.larger
            }
            StyledText {
                Layout.fillWidth: true
                text: root.text
                font: header.font
                color: Appearance.colors.colOnSecondaryContainer
            }
            ColorSwatch {
                color: root.value !== "" ? root.value : "transparent"

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: root.value === ""
                    text: "hdr_auto"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
            MaterialSymbol {
                text: "expand_more"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSecondaryContainer
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }

    Revealer {
        Layout.fillWidth: true
        vertical: true
        reveal: root.expanded

        ColumnLayout {
            width: parent.width
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 8

                Rectangle {
                    id: svArea
                    Layout.fillWidth: true
                    implicitHeight: 160
                    radius: Appearance.rounding.verysmall
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: "#ffffff"
                        }
                        GradientStop {
                            position: 1
                            color: Qt.hsva(root.hue, 1, 1, 1)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 1
                                color: "#000000"
                            }
                        }
                    }

                    PickerHandle {
                        x: root.saturation * svArea.width - width / 2
                        y: (1 - root.brightness) * svArea.height - height / 2
                        color: Qt.hsva(root.hue, root.saturation, root.brightness, 1)
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: Qt.CrossCursor
                        function update(mouse) {
                            root.pick(root.hue, root.clamp01(mouse.x / width), 1 - root.clamp01(mouse.y / height));
                        }
                        onPressed: mouse => update(mouse)
                        onPositionChanged: mouse => update(mouse)
                    }
                }

                Rectangle {
                    id: hueStrip
                    implicitWidth: 24
                    Layout.fillHeight: true
                    radius: Appearance.rounding.verysmall
                    gradient: Gradient {
                        GradientStop { position: 0 / 6; color: "#ff0000" }
                        GradientStop { position: 1 / 6; color: "#ffff00" }
                        GradientStop { position: 2 / 6; color: "#00ff00" }
                        GradientStop { position: 3 / 6; color: "#00ffff" }
                        GradientStop { position: 4 / 6; color: "#0000ff" }
                        GradientStop { position: 5 / 6; color: "#ff00ff" }
                        GradientStop { position: 6 / 6; color: "#ff0000" }
                    }

                    PickerHandle {
                        x: (hueStrip.width - width) / 2
                        y: root.hue * hueStrip.height - height / 2
                        color: Qt.hsva(root.hue, 1, 1, 1)
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        function update(mouse) {
                            root.pick(root.clamp01(mouse.y / height), root.saturation, root.brightness);
                        }
                        onPressed: mouse => update(mouse)
                        onPositionChanged: mouse => update(mouse)
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 6

                Repeater {
                    model: root.presets
                    delegate: ColorSwatch {
                        required property color modelData
                        color: modelData

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.picked(parent.modelData.toString())
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 8

                MaterialTextField {
                    id: hexField
                    readonly property bool valid: /^(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8})?$/.test(text)
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Hex color, e.g. #ffffff")
                    text: root.value
                    wrapMode: TextInput.NoWrap
                    color: valid ? Appearance.m3colors.m3onSurface : Appearance.colors.colError
                    onTextEdited: {
                        if (valid)
                            root.picked(text);
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: "restart_alt"
                    mainText: Translation.tr("Default")
                    enabled: root.value !== ""
                    onClicked: root.picked("")
                }
            }
        }
    }

    component ColorSwatch: Rectangle {
        implicitWidth: 24
        implicitHeight: 24
        radius: Appearance.rounding.full
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
    }

    component PickerHandle: Rectangle {
        width: 16
        height: 16
        radius: Appearance.rounding.full
        border.width: 2
        border.color: "#ffffff"
    }
}
