import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root

  moduleName: "waldseelen.market"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "Open Plugin Marketplace (Super+N)"

    iconComponent: Component {
      Item {
        MarketplaceIcon {
          anchors.centerIn: parent
          iconSize: Math.min(parent.width, parent.height) * 0.82
          color: button.foreground
        }
      }
    }

    onPressed: function(buttonCode) {
      if (root.bar && typeof root.bar.run === "function") {
        root.bar.run("omarchy-shell shell toggle waldseelen.market '{}'")
      } else {
        Util.execDetached("omarchy-shell shell toggle waldseelen.market '{}'")
      }
    }
  }
}
