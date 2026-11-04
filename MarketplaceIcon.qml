import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  property real iconSize: Style.bar.iconCanvas
  property color color: Color.foreground

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Shape {
    width: 24
    height: 24
    anchors.centerIn: parent
    scale: root.iconSize / 24
    preferredRendererType: Shape.CurveRenderer

    // Cable geometry from Lucide Icons (https://lucide.dev)
    // Copyright (c) 2022-present Lucide Contributors.
    // Licensed under the ISC License:
    //
    // Permission to use, copy, modify, and/or distribute this software for any purpose
    // with or without fee is hereby granted, provided that the above copyright notice
    // and this permission notice appear in all copies.
    //
    // THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    // REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
    // FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    // INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
    // OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
    // TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
    // THIS SOFTWARE.
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.color
      strokeWidth: 2.25
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin

      PathSvg {
        path: "M17 19a1 1 0 0 1-1-1v-2a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2a1 1 0 0 1-1 1Z M17 21v-2M19 14V6.5a1 1 0 0 0-7 0v11a1 1 0 0 1-7 0V10M21 21v-2M3 5V3 M4 10a2 2 0 0 1-2-2V6a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2a2 2 0 0 1-2 2Z M7 5V3"
      }
    }
  }
}
