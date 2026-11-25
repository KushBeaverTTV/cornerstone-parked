import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Parked.js" as Parked

// Auto-hiding bar pill for minimized & special-workspace windows.
// Takes 0px when nothing is parked; left click opens drawer, right click restores all minimized.
Panel {
  id: root
  moduleName: "cornerstone.parked"
  ipcTarget: "cornerstone-parked"
  manageIpc: false

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor("cornerstone.parked") : null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color muted: Qt.darker(foreground, 1.55)
  readonly property color hairline: Qt.darker(foreground, 2.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var windows: service ? service.windows : []
  readonly property int count: service ? service.count : 0
  readonly property int minimizedCount: service ? service.minimizedCount : 0

  visible: count > 0 || opened
  onCountChanged: if (count === 0 && opened) close()
  onOpenedChanged: if (opened && service) service.refresh()

  readonly property string barTooltip: count + " parked window" + (count === 1 ? "" : "s")
    + (minimizedCount > 0 ? " (" + minimizedCount + " minimized)" : "")

  function iconFor(cls, title) {
    var appsRev = DesktopEntries.applications.values.length
    var names = Parked.appIconCandidates(cls, title)
    for (var i = 0; i < names.length; i++) {
      var hit = Quickshell.iconPath(names[i], true)
      if (hit) return hit
    }
    for (var j = 0; j < names.length; j++) {
      var d = DesktopEntries.byId(names[j]) || DesktopEntries.heuristicLookup(names[j])
      if (d && d.icon) {
        var ic = String(d.icon)
        if (ic.charAt(0) === "/") return "file://" + ic
        var p = Quickshell.iconPath(ic, true)
        if (p) return p
      }
    }
    return ""
  }

  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    visible: root.visible
    bar: root.bar
    labelVisible: false
    hasVisualContent: root.visible
    horizontalMargin: 5
    fixedWidth: vertical ? -1 : Math.max(Style.bar.iconSlot, pill.implicitWidth + scaledHorizontalMargin * 2)
    fixedHeight: vertical ? Math.max(Style.bar.iconSlot, pill.implicitHeight + Style.space(6)) : -1
    tooltipText: root.opened ? "" : root.barTooltip
    onPressed: function(code) {
      if (code === Qt.RightButton && root.service && root.minimizedCount > 0) root.service.restoreAllMinimized()
      else root.toggle()
    }

    Row {
      id: pill
      anchors.centerIn: parent
      scale: button.pressScale
      spacing: Style.space(4)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: "󰖰"
        color: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.bar.iconFont
        renderType: Text.NativeRendering
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: String(root.count)
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        font.features: { "tnum": 1 }
        renderType: Text.NativeRendering
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(350))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(520))

    content: PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") { if (root.service) root.service.refresh() }
      }
      clip: true

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: titleText.implicitHeight
          Text {
            id: titleText
            anchors.left: parent.left
            textFormat: Text.PlainText
            text: "Parked Windows (" + root.count + ")"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }
          Text {
            visible: root.minimizedCount > 1
            anchors.right: parent.right
            anchors.verticalCenter: titleText.verticalCenter
            textFormat: Text.PlainText
            text: "Restore all minimized"
            color: restoreAllA.containsMouse ? Color.accent : root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea {
              id: restoreAllA
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { if (root.service) root.service.restoreAllMinimized(); root.close() }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: root.hairline }

        Column {
          width: parent.width
          spacing: Style.space(5)

          Repeater {
            model: root.windows.slice(0, 10)
            Rectangle {
              required property var modelData
              readonly property string iconUrl: root.iconFor(modelData.appClass, modelData.title)
              width: parent.width
              height: Style.space(42)
              radius: Style.space(6)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b,
                             wArea.containsMouse ? 0.14 : 0.05)
              Behavior on color { ColorAnimation { duration: Style.duration(120) } }

              MouseArea {
                id: wArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.service) root.service.restore(modelData.address); root.close() }
              }

              Item {
                id: icBox
                width: Style.space(22); height: Style.space(22)
                anchors.left: parent.left
                anchors.leftMargin: Style.space(9)
                anchors.verticalCenter: parent.verticalCenter
                Image {
                  id: icImg
                  anchors.fill: parent
                  visible: iconUrl !== "" && status === Image.Ready
                  source: iconUrl
                  sourceSize.width: 48; sourceSize.height: 48
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  smooth: true
                  mipmap: true
                }
                Text {
                  anchors.centerIn: parent
                  visible: !icImg.visible
                  textFormat: Text.PlainText
                  text: "󰖯"
                  color: root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: icBox.right
                anchors.leftMargin: Style.space(8)
                anchors.right: closeBtn.left
                anchors.rightMargin: Style.space(6)
                spacing: 1
                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: modelData.title
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: modelData.spaceLabel + " · " + modelData.appClass
                  color: modelData.minimized ? root.muted : Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                id: closeBtn
                width: Style.space(24); height: Style.space(24); radius: Style.space(5)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                color: cArea.containsMouse ? Util.alpha(Color.urgent, 0.25) : "transparent"
                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: "󰅖"
                  color: cArea.containsMouse ? Color.urgent : root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                MouseArea {
                  id: cArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (root.service) root.service.closeWindow(modelData.address)
                }
              }
            }
          }
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          text: "Click row = bring here · × = close · right-click pill = restore all minimized"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
