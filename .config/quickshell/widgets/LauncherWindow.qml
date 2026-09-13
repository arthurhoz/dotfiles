import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: launcherWindow

  color: "transparent"

  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.layer: WlrLayer.Overlay

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  visible: false

  readonly property color colBg: "#1a1b26"
  readonly property color colBgAlt: "#24283b"
  readonly property color colSurface: "#292e42"
  readonly property color colSelectBg: "#332e59"
  readonly property color colFg: "#c0caf5"
  readonly property color colFgDim: "#565f89"
  readonly property color colPurple: "#bb9af7"
  readonly property color colMagenta: "#f7768e"
  readonly property color colBorder: "#3d59a1"

  readonly property int windowWidth: 640
  readonly property int windowHeight: 440
  readonly property int columns: 3
  readonly property int itemHeight: 120
  readonly property string fontFamily: "Iosevka"

  property string searchQuery: ""
  property var appList: []

  function updateAppList() {
    let all = [...DesktopEntries.applications.values];
    let q = searchQuery.trim().toLowerCase();

    if (q === "") {
      appList = all.sort((a, b) => a.name.localeCompare(b.name));
    } else {
      appList = all.filter(app => {
        let nameMatch = app.name && app.name.toLowerCase().includes(q);
        let commentMatch = app.comment && app.comment.toLowerCase().includes(q);
        let genericMatch = app.genericName && app.genericName.toLowerCase().includes(q);
        return nameMatch || commentMatch || genericMatch;
      }).sort((a, b) => a.name.localeCompare(b.name));
    }
    grid.currentIndex = appList.length > 0 ? 0 : -1;
  }

  Component.onCompleted: updateAppList()

  function launchSelected() {
    if (grid.currentIndex >= 0 && grid.currentIndex < appList.length) {
      appList[grid.currentIndex].execute();
      launcherWindow.visible = false;
      searchInput.text = "";
    }
  }

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      launcherWindow.visible = !launcherWindow.visible;
      if (launcherWindow.visible) {
        searchInput.text = "";
        launcherWindow.updateAppList();
        searchInput.forceActiveFocus();
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "transparent"

    MouseArea {
      anchors.fill: parent
      onClicked: launcherWindow.visible = false
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: launcherWindow.windowWidth
    height: launcherWindow.windowHeight
    radius: 12
    color: launcherWindow.colBg
    border.color: Qt.rgba(187, 154, 247, 0.2)
    border.width: 1

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 60
        radius: 8
        color: launcherWindow.colBgAlt
        border.color: searchInput.activeFocus ? launcherWindow.colPurple : Qt.rgba(1, 1, 1, 0.05)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10

          Text {
            text: ""
            font.pixelSize: 14
            color: launcherWindow.colPurple
          }

          TextField {
            id: searchInput
            Layout.fillWidth: true
            placeholderText: "Try searching something..."
            placeholderTextColor: launcherWindow.colFgDim
            color: launcherWindow.colFg
            font.pixelSize: 16
            font.family: launcherWindow.fontFamily
            background: null

            onTextChanged: {
              launcherWindow.searchQuery = text;
              launcherWindow.updateAppList();
            }

            Keys.onEscapePressed: launcherWindow.visible = false

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Down) {
                grid.currentIndex = Math.min(grid.currentIndex + launcherWindow.columns, grid.count - 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                grid.currentIndex = Math.max(grid.currentIndex - launcherWindow.columns, 0);
                event.accepted = true;
              } else if (event.key === Qt.Key_Right) {
                grid.currentIndex = Math.min(grid.currentIndex + 1, grid.count - 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Left) {
                grid.currentIndex = Math.max(grid.currentIndex - 1, 0);
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                launcherWindow.launchSelected();
                event.accepted = true;
              }
            }
          }
        }
      }

      GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        cellWidth: width / launcherWindow.columns
        cellHeight: launcherWindow.itemHeight

        model: launcherWindow.appList

        delegate: Rectangle {
          required property var modelData
          required property int index

          width: grid.cellWidth - 8
          height: grid.cellHeight - 8
          radius: 10
          clip: true

          property bool isSelected: grid.currentIndex === index

          color: isSelected ? launcherWindow.colSelectBg : launcherWindow.colBgAlt
          border.color: isSelected ? launcherWindow.colPurple : "transparent"
          border.width: isSelected ? 2 : 0

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: grid.currentIndex = index
            onClicked: launcherWindow.launchSelected()
          }

          Item {
            id: iconContainer
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: 45
            height: 45

            Image {
              id: appIcon
              anchors.fill: parent
              sourceSize: Qt.size(45, 45)
              source: Quickshell.iconPath(modelData.icon ?? "", "application-x-executable")
              fillMode: Image.PreserveAspectFit
              visible: status === Image.Ready
            }

            Rectangle {
              anchors.fill: parent
              radius: 10
              color: isSelected ? launcherWindow.colBg : launcherWindow.colBgAlt
              border.color: launcherWindow.colPurple
              border.width: 1
              visible: appIcon.status !== Image.Ready

              Text {
                anchors.centerIn: parent
                text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                color: launcherWindow.colPurple
                font.pixelSize: 22
                font.family: launcherWindow.fontFamily
                font.weight: Font.Bold
              }
            }
          }

          Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 6

            text: modelData.name
            color: isSelected ? launcherWindow.colPurple : launcherWindow.colFg
            font.pixelSize: 15
            font.family: launcherWindow.fontFamily
            font.weight: isSelected ? Font.Bold : Font.Medium

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
