import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Io

PanelWindow {
  id: barWindow

  visible: true

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 36
  color: "transparent"

  IpcHandler {
    target: "bar"

    function toggle(): void {
      barWindow.visible = !barWindow.visible
    }
  }

  Process {
    id: pavuControlProc
    command: ["pavucontrol"]
  }

  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      tempProc.running = true
      backlightProc.running = true
      netProc.running = true
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: 8

    RowLayout {
      spacing: 8

      Text {
        id: archLogo
        text: "\uf303"
        font.pixelSize: 20
        color: "#1793d1"
        Layout.alignment: Qt.AlignVCenter
      }

      RowLayout {
        spacing: 5

        Repeater {
          model: Hyprland.workspaces

          Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: modelData.active ? "#cba6f7" : "#313244"

            Text {
              anchors.centerIn: parent
              text: modelData.id
              color: modelData.active ? "#11111b" : "#cdd6f4"
              font.pixelSize: 11
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
          }
        }
      }

      BarCapsule {
        id: netWidget
        property string netState: "Disconnected"
        property string netIcon: "⚠"

        icon: netIcon
        text: netState

        Process {
          id: netProc
          command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev | grep ':connected' | head -n1"]
          stdout: SplitParser {
            onRead: data => {
              let line = data.trim();
              if (line.startsWith("wifi")) {
                netWidget.netIcon = ""
                netWidget.netState = line.split(":")[2] || "Wi-Fi"
              } else if (line.startsWith("ethernet")) {
                netWidget.netIcon = ""
                netWidget.netState = "Ethernet"
              } else {
                netWidget.netIcon = "⚠"
                netWidget.netState = "Disconnected"
              }
            }
          }
        }
      }

      BarCapsule {
        id: audioWidget
        property int volumeVal: 0
        property bool isMuted: false

        icon: {
          if (isMuted) return ""
          if (volumeVal <= 20) return ""
          if (volumeVal <= 60) return ""
          return ""
        }

        text: isMuted ? "Muted" : volumeVal + "%"

        Process {
          id: audioProc
          command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
          running: true
          stdout: SplitParser {
            onRead: data => {
              let str = data.trim();
              audioWidget.isMuted = str.includes("[MUTED]");
              let parts = str.split(" ");
              if (parts.length >= 2) {
                let vol = parseFloat(parts[1]);
                if (!isNaN(vol)) audioWidget.volumeVal = Math.round(vol * 100);
              }
            }
          }
        }

        Timer {
          interval: 500
          running: true
          repeat: true
          onTriggered: audioProc.running = true
        }

        MouseArea {
          anchors.fill: parent
          onClicked: pavuControlProc.running = true
        }
      }
    }

    Item {
      Layout.fillWidth: true
    }

    RowLayout {
      spacing: 5

      BarCapsule {
        id: tempWidget
        property int tempVal: 0

        icon: {
          if (tempVal >= 80) return ""
          if (tempVal >= 50) return ""
          return ""
        }
        text: tempVal + "°C"

        Process {
          id: tempProc
          command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)}'"]
          stdout: SplitParser {
            onRead: data => {
              let val = parseInt(data.trim());
              if (!isNaN(val)) tempWidget.tempVal = val;
            }
          }
        }
      }

      BarCapsule {
        id: cpuWidget
        property int cpuUsage: 0

        icon: ""
        text: cpuUsage + "%"

        Process {
          id: cpuProc
          command: ["sh", "-c", "top -b -n 1 | awk '/Cpu\\(s\\):/ {print int($2 + $4)}'"]
          stdout: SplitParser {
            onRead: data => {
              let val = parseInt(data.trim());
              if (!isNaN(val)) cpuWidget.cpuUsage = val;
            }
          }
        }
      }

      BarCapsule {
        id: memWidget
        property int memUsage: 0

        icon: ""
        text: memUsage + "%"

        Process {
          id: memProc
          command: ["sh", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2 * 100}'"]
          stdout: SplitParser {
            onRead: data => {
              let val = parseInt(data.trim());
              if (!isNaN(val)) memWidget.memUsage = val;
            }
          }
        }
      }

      BarCapsule {
        id: backlightWidget
        property int brightnessPercent: 0

        icon: ""
        text: brightnessPercent + "%"

        Process {
          id: backlightProc
          command: ["sh", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
          stdout: SplitParser {
            onRead: data => {
              let val = parseInt(data.trim());
              if (!isNaN(val)) backlightWidget.brightnessPercent = val;
            }
          }
        }
      }

      BarCapsule {
        property var dev: UPower.displayDevice
        property real pct: dev ? Math.round(dev.percentage * 100) : 0
        property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false

        icon: {
          if (charging) return ""
          if (pct <= 15) return ""
          if (pct <= 35) return ""
          if (pct <= 60) return ""
          if (pct <= 85) return ""
          return ""
        }
        text: pct + "%"
      }
    }
  }

  BarCapsule {
    id: clockWidget
    anchors.centerIn: parent

    property string timeText: ""
    icon: "󰥔"
    text: timeText

    Timer {
      interval: 1000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        clockWidget.timeText = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm")
      }
    }
  }

  component BarCapsule: Rectangle {
    id: capsuleRoot
    property string icon: ""
    property string text: ""

    implicitHeight: 28
    implicitWidth: capsuleRow.implicitWidth + 14
    radius: 6
    color: "#313244"

    RowLayout {
      id: capsuleRow
      anchors.centerIn: parent
      spacing: 5

      Text {
        text: capsuleRoot.icon
        color: "#cba6f7"
        font.pixelSize: 17
      }

      Text {
        text: capsuleRoot.text
        color: "#cdd6f4"
        font.pixelSize: 14
        font.weight: Font.Medium
      }
    }
  }
}
