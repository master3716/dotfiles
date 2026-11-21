import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

// Mouse, touchpad and keyboard. Every change is live (hyprctl eval) and
// kept in ~/.config/hypr/input.lua, see services/Input.qml. custom.lua is
// read after that file, so a value set there wins over this page.
SettingsPage {
    id: page

    NProcess { id: sh; function run(cmd) { command = ["sh", "-c", cmd]; running = true; } }

    // Named one by one: Config's own notes say a property reached through
    // a built string reads as its default, so no Config[key] here.
    function set(key: string, v: var): void {
        switch (key) {
        case "inputSensitivity":      Config.inputSensitivity = v; break;
        case "inputAccel":            Config.inputAccel = v; break;
        case "inputNaturalScroll":    Config.inputNaturalScroll = v; break;
        case "inputFollowMouse":      Config.inputFollowMouse = v; break;
        case "inputRepeatRate":       Config.inputRepeatRate = v; break;
        case "inputRepeatDelay":      Config.inputRepeatDelay = v; break;
        case "inputNumlock":          Config.inputNumlock = v; break;
        case "touchpadNaturalScroll": Config.touchpadNaturalScroll = v; break;
        case "touchpadDisableTyping": Config.touchpadDisableTyping = v; break;
        case "touchpadScrollFactor":  Config.touchpadScrollFactor = v; break;
        default: return;
        }
        Config.save();
        Input.apply();
    }

    SettingsSection {
        title: "Mouse"

        SettingRow {
            key: "inputSensitivity"
            label: "Pointer speed"
            hint: "Added to the mouse's own speed, from -1 to +1"
            DotSlider {
                implicitWidth: Theme.px(190)
                count: 21
                value: (Config.inputSensitivity + 1) / 2
                display: (Config.inputSensitivity > 0 ? "+" : "") + Number(Config.inputSensitivity).toFixed(1)
                onMoved: (v) => page.set("inputSensitivity", Math.round((v * 2 - 1) * 10) / 10)
            }
        }

        SettingRow {
            key: "inputAccel"
            label: "Acceleration"
            hint: Config.inputAccel === "flat"
                ? "Flat: the same distance whatever the speed, for games"
                : (Config.inputAccel === "adaptive" ? "Adaptive: faster moves go further"
                                                    : "Whatever the device does by default")
        }

        DotPicker {
            options: [
                { label: "Default", value: "" },
                { label: "Adaptive", value: "adaptive" },
                { label: "Flat", value: "flat" }
            ]
            current: Config.inputAccel
            onPicked: (v) => page.set("inputAccel", v)
        }

        SettingRow {
            key: "inputNaturalScroll"
            label: "Natural scrolling"
            hint: "The wheel moves the page, not the view"
            DotSwitch {
                checked: Config.inputNaturalScroll
                onToggled: (v) => page.set("inputNaturalScroll", v)
            }
        }

        SettingRow {
            key: "inputFollowMouse"
            label: "Focus follows the pointer"
            hint: Config.inputFollowMouse ? "Hovering a window focuses it" : "Click to focus"
            DotSwitch {
                checked: Config.inputFollowMouse
                onToggled: (v) => page.set("inputFollowMouse", v)
            }
        }
    }

    SettingsSection {
        title: "Touchpad"

        SettingRow {
            key: "touchpadNaturalScroll"
            label: "Natural scrolling"
            DotSwitch {
                checked: Config.touchpadNaturalScroll
                onToggled: (v) => page.set("touchpadNaturalScroll", v)
            }
        }

        SettingRow {
            key: "touchpadDisableTyping"
            label: "Ignore while typing"
            DotSwitch {
                checked: Config.touchpadDisableTyping
                onToggled: (v) => page.set("touchpadDisableTyping", v)
            }
        }

        SettingRow {
            key: "touchpadScrollFactor"
            label: "Scroll speed"
            DotSlider {
                implicitWidth: Theme.px(190)
                count: 16
                value: (Config.touchpadScrollFactor - 0.1) / 1.4
                display: Number(Config.touchpadScrollFactor).toFixed(1) + "x"
                onMoved: (v) => page.set("touchpadScrollFactor", Math.round((0.1 + v * 1.4) * 10) / 10)
            }
        }
    }

    SettingsSection {
        title: "Keyboard"

        SettingRow {
            key: "inputRepeatDelay"
            label: "Repeat delay"
            hint: "How long a key is held before it repeats"
            DotSlider {
                implicitWidth: Theme.px(190)
                count: 16
                value: (Config.inputRepeatDelay - 150) / 750
                display: Config.inputRepeatDelay + " ms"
                onMoved: (v) => page.set("inputRepeatDelay", Math.round((150 + v * 750) / 50) * 50)
            }
        }

        SettingRow {
            key: "inputRepeatRate"
            label: "Repeat rate"
            DotSlider {
                implicitWidth: Theme.px(190)
                count: 16
                value: (Config.inputRepeatRate - 10) / 50
                display: Config.inputRepeatRate + " /s"
                onMoved: (v) => page.set("inputRepeatRate", Math.round(10 + v * 50))
            }
        }

        SettingRow {
            key: "inputNumlock"
            label: "Num Lock on at login"
            DotSwitch {
                checked: Config.inputNumlock
                onToggled: (v) => page.set("inputNumlock", v)
            }
        }

    }

    SettingsSection {
        title: "Keybindings"

        SettingRow {
            key: "keybinds"
            label: "Keyboard Shortcuts & Keybinds"
            hint: "Customise default actions or add your own key combinations"
            NPillButton {
                text: "Reload Binds"
                onActivated: Keybinds.apply()
            }
        }

        Repeater {
            model: Keybinds.coreActions

            Rectangle {
                id: actionRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Theme.px(38)
                radius: Theme.r.chip
                color: Theme.c.surface2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.px(12)
                    anchors.rightMargin: Theme.px(10)
                    spacing: Theme.px(10)

                    NText {
                        Layout.fillWidth: true
                        text: actionRow.modelData.label
                        font.pixelSize: Theme.f.body
                        elide: Text.ElideRight
                    }

                    NField {
                        id: kf
                        implicitWidth: Theme.px(170)
                        implicitHeight: Theme.px(26)
                        text: Keybinds.currentKeyFor(actionRow.modelData.id, actionRow.modelData.defaultKey)
                        onCommitted: (val) => Keybinds.setOverride(actionRow.modelData.id, val, actionRow.modelData.defaultKey)
                        onSubmitted: (val) => Keybinds.setOverride(actionRow.modelData.id, val, actionRow.modelData.defaultKey)
                    }

                    CircleButton {
                        icon: "󰅖"
                        size: Theme.px(22)
                        visible: Keybinds.currentKeyFor(actionRow.modelData.id, actionRow.modelData.defaultKey) !== actionRow.modelData.defaultKey
                        onActivated: Keybinds.resetOverride(actionRow.modelData.id)
                    }
                }
            }
        }

        SettingRow {
            label: "Custom Keybindings"
            hint: (Config.customKeybinds ?? []).length === 0
                ? "No custom binds added yet. Add one below:"
                : "Your custom hotkeys:"
        }

        Repeater {
            model: Config.customKeybinds ?? []

            Rectangle {
                id: customRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Theme.px(36)
                radius: Theme.r.tiny
                color: Theme.c.surface2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.px(12)
                    anchors.rightMargin: Theme.px(8)
                    spacing: Theme.px(10)

                    KeyCap { text: customRow.modelData.key }

                    NText {
                        Layout.fillWidth: true
                        text: customRow.modelData.command
                        color: Theme.c.onDim
                        elide: Text.ElideRight
                    }

                    CircleButton {
                        icon: "󰅖"
                        size: Theme.px(22)
                        onActivated: Keybinds.removeCustom(customRow.index)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.px(42)
            radius: Theme.r.chip
            color: Theme.c.surface3

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.px(10)
                anchors.rightMargin: Theme.px(10)
                spacing: Theme.px(8)

                NField {
                    id: addKeyField
                    implicitWidth: Theme.px(140)
                    implicitHeight: Theme.px(28)
                    placeholder: "SUPER + D"
                }

                NField {
                    id: addCmdField
                    Layout.fillWidth: true
                    implicitHeight: Theme.px(28)
                    placeholder: "Command (e.g. vesktop)"
                    onSubmitted: {
                        if (Keybinds.addCustom(addKeyField.text, addCmdField.text)) {
                            addKeyField.clear();
                            addCmdField.clear();
                        }
                    }
                }

                NPillButton {
                    text: "Add"
                    onActivated: {
                        if (Keybinds.addCustom(addKeyField.text, addCmdField.text)) {
                            addKeyField.clear();
                            addCmdField.clear();
                        }
                    }
                }
            }
        }

        SettingRow {
            label: "Manual Lua file"
            hint: "For complex window rules, multi-line gestures or raw Hyprland scripts"
            NPillButton {
                text: "Edit custom.lua"
                onActivated: sh.run("touch ~/.config/hypr/custom.lua && xdg-open ~/.config/hypr/custom.lua")
            }
        }
    }

    SettingsSection {
        title: "Input file"

        SettingRow {
            key: "inputReset"
            label: Input.written ? "~/.config/hypr/input.lua" : "Nothing written yet"
            hint: Input.error !== ""
                ? "Hyprland refused it: " + Input.error
                : "custom.lua is read after this file, so its values win"
            NPillButton {
                text: "Back to defaults"
                visible: Input.written
                onActivated: Input.reset()
            }
        }
    }
}
