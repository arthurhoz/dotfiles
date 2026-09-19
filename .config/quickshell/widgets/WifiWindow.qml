import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
  id: wifiWindow
  visible: false
  width: 550
  implicitHeight: 450
  color: "#1E1E2E"

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property var networks: []
  property var activeNetworkBSSID: ""

  Shortcut {
    sequence: "Escape"
    onActivated: {
      wifiWindow.visible = false;
    }
  }

  IpcHandler {
    target: "wifi"

    function toggle(): void {
      wifiWindow.visible = !wifiWindow.visible
    }
  }

  Process {
    id: wifiProcess
    command: ["nmcli", "-t", "-f", "SSID,BAND,RATE,BSSID", "device", "wifi", "list"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n");
        let list = [];

        for (let i = 0; i < lines.length; i++) {
          let line = lines[i].replace(/\\:/g, "|");
          let parts = line.split(":");

          let data = {
            ssid: parts[0],
            band: parts[1],
            rate: parts[2],
            bssid: parts[3].replace(/\|/g, ":")
          };

          if (data.ssid !== "--" && data.ssid !== "") {
            list.push(data);
          }
        }

        wifiWindow.networks = list;
      }
    }
  }

  Process {
    id: connectedProcess
    running: false
    command: ["nmcli", "-t", "-f", "ACTIVE,BSSID", "device", "wifi"]

    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n");
        let list = [];

        for (let i = 0; i < lines.length; i++) {
          let line = lines[i].replace(/\\:/g, "|");
          let parts = line.split(":");

          if (parts[0] == "yes") {
            let bssid = parts[1].replace(/\|/g, ":");
            wifiWindow.activeNetworkBSSID = bssid;
            break;
          }
        }
      }
    }
  }

  Process {
    property string bssid: ""
    property string password: ""

    id: connectProcess
    command: ["nmcli", "device", "wifi", "connect", bssid, ...(password !== "" ? ["password", password] : [])]
    running: false
  }

  Process {
    id: disconnectProcess
    command: ["nmcli", "device", "disconnect", "wlan0"]
    running: false
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 10

    Text {
      text: "Available Networks"
      color: "#CDD6F4"
      font.pixelSize: 24
      font.bold: true
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 10
      model: wifiWindow.networks

      delegate: Rectangle {
        width: ListView.view.width
        height: 50
        color: "#313244"
        radius: 6

        required property var modelData

        RowLayout {
          anchors.fill: parent
          anchors.margins: 10

          Text {
            text: modelData.ssid + " (" + modelData.band + "/" + modelData.rate + ")"
            color: "#CDD6F4"
            Layout.fillWidth: true
            font.pixelSize: 15
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
          }

          TextField {
            id: passwordInput
            placeholderText: "Password"
            echoMode: TextInput.NoEcho
            horizontalAlignment: TextInput.AlignHCenter
            
            Layout.preferredWidth: 80
            Layout.preferredHeight: 35
            Layout.alignment: Qt.AlignVCenter
            color: "#CDD6F4"
            placeholderTextColor: "#6C7086"

            background: Rectangle {
              color: "#1E1E2E"
              radius: 6
              border.color: "#45475A"
              border.width: 1
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                passwordInput.forceActiveFocus();
              }
            }
          }

          Button {
            text: (modelData.bssid !== wifiWindow.activeNetworkBSSID) ? "Connect" : "Disconnect" 
            Layout.alignment: Qt.AlignVCenter

            contentItem: Text {
              text: parent.text
              color: "#CDD6F4"
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              font.pixelSize: 13
              font.bold: true
            }

            background: Rectangle {
              implicitHeight: 35
              implicitWidth: 70
              color: "#4B0082"
              radius: 6
            }

            onClicked: {
              if (modelData.bssid !== wifiWindow.activeNetworkBSSID) {
                connectProcess.bssid = modelData.bssid;
                connectProcess.password = passwordInput.text;
                connectProcess.running = true;
              } else {
                disconnectProcess.running = true;
              }
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 3000
    running: wifiWindow.visible
    repeat: true
    onTriggered: {
      wifiProcess.running = true;
      connectedProcess.running = true;
    }
  }
}
