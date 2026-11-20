import QtQuick
import QtQuick.Layouts
import ".."

// In-place voice note transport. A hollow circle and a red rail,
// nothing that looks like a system media player.
// (QtMultimedia made optional so missing multimedia plugin does not break entire desktop shell)
Item {
    id: root
    property string path: ""

    readonly property bool playing: false
    readonly property real dur: 0
    readonly property real progress: 0

    property real pos: 0

    implicitHeight: Theme.px(36)

    function toggle(): void {}
    function seek(v: real): void {}

    function clock(ms: real): string {
        const t = Math.max(0, Math.floor((ms || 0) / 1000));
        const m = Math.floor(t / 60);
        const s = t % 60;
        return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
    }

    RowLayout {
        anchors.fill: parent
        spacing: Theme.px(10)

        CircleButton {
            icon: root.playing ? "󰏤" : "󰐊"
            filled: root.playing
            size: Theme.px(30)
            onActivated: root.toggle()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: rail
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Theme.z.rail
                radius: height / 2
                color: Theme.c.surface3

                Rectangle {
                    width: Math.max(height, rail.width * root.progress)
                    height: parent.height
                    radius: height / 2
                    color: Theme.c.red
                }
            }
        }

        Text {
            text: root.clock(root.pos)
            color: Theme.c.onDim
            font.family: Theme.f.mono
            font.pixelSize: Theme.f.micro
        }
    }
}
