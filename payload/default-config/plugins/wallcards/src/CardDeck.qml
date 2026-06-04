import qs.Commons
import qs.Widgets
import QtQuick

Item {
  id: cardDeck

  required property int animationDuration
  property real animationIndex: 0
  required property int cardRadius
  required property int cardSpacing
  required property int cardStripWidth
  required property int cardsShown
  property real centerWidth: parent.width * centerWidthRatio
  required property real centerWidthRatio
  property real centerX: width / 2 - centerWidth / 2
  property int currentIndex: 0
  required property int filteredCount
  required property var filteredModel
  property int halfVisible: Math.floor(visibleCount / 2)
  property real runningIndex: 0
  required property real shearFactor
  property int sideCount: Math.floor(cardsShown / 2) - 1
  property int visibleCount: cardsShown

  signal applyRequested(int index)

  function navigateTo(idx) {
    var maxLead = Math.max(1, halfVisible - 1);
    if (Math.abs(runningIndex - animationIndex) >= maxLead)
      return;

    var newIdx = wrappedIndex(idx);
    var diff = 0;

    if (filteredCount > 0) {
      diff = newIdx - currentIndex;
      var half = filteredCount / 2;
      if (diff > half)
        diff -= filteredCount;
      else if (diff < -half)
        diff += filteredCount;
    }

    runningIndex += diff;
    animationIndex = runningIndex;
    currentIndex = newIdx;
  }
  function randomJump() {
    var rnd = Math.floor(Math.random() * filteredCount);
    if (rnd === currentIndex)
      rnd = (rnd + 1) % filteredCount;
    navigateTo(rnd);
  }
  function slotToWidth(slot) {
    var t = Math.min(Math.abs(slot), 1);
    return centerWidth + (cardStripWidth - centerWidth) * t;
  }
  function slotToX(slot) {
    var rightEdge = centerX + centerWidth + cardSpacing;
    var leftEdge = centerX - cardSpacing - cardStripWidth;

    if (slot >= 0 && slot <= 1)
      return centerX + (rightEdge - centerX) * slot;
    if (slot > 1)
      return rightEdge + (slot - 1) * (cardStripWidth + cardSpacing);
    if (slot >= -1 && slot < 0)
      return centerX + (leftEdge - centerX) * (-slot);
    if (slot < -1)
      return leftEdge + (slot + 1) * (cardStripWidth + cardSpacing);
    return 0;
  }
  function wrappedIndex(idx) {
    return ((idx % filteredCount) + filteredCount) % filteredCount;
  }

  function jumpTo(idx) {
    animBehavior.enabled = false;
    runningIndex = idx;
    animationIndex = idx;
    currentIndex = idx;
    reenableTimer.restart();
  }

  Timer {
    id: reenableTimer

    interval: 0

    onTriggered: animBehavior.enabled = true
  }

  width: (cardsShown - 3) * cardStripWidth + (cardsShown - 3) * cardSpacing + centerWidth

  Behavior on animationIndex {
    id: animBehavior

    NumberAnimation {
      duration: cardDeck.animationDuration
      easing.type: Easing.OutCubic
    }
  }
  transform: Matrix4x4 {
    property real s: cardDeck.shearFactor

    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
  }

  Repeater {
    model: cardDeck.filteredCount > 0 ? cardDeck.visibleCount : 0

    delegate: Rectangle {
      id: card

      property real fractionalSlot: offset + (cardDeck.runningIndex - cardDeck.animationIndex)
      property bool isCenter: offset === 0
      property int modelIndex: cardDeck.wrappedIndex(Math.round(cardDeck.runningIndex) + offset)
      property int offset: index - cardDeck.halfVisible

      signal applyRequested

      border.color: isCenter ? Color.mOutline : Color.mSurface
      border.width: isCenter ? Style.borderM : Style.borderS
      color: "transparent"
      height: cardDeck.height
      opacity: Math.max(0, Math.min(1, cardDeck.halfVisible - Math.abs(fractionalSlot)))
      radius: cardDeck.cardRadius
      visible: (x + width) > 0 && x < cardDeck.width
      width: cardDeck.slotToWidth(fractionalSlot)
      x: cardDeck.slotToX(fractionalSlot)
      y: 0
      z: isCenter ? 100 : cardDeck.visibleCount - Math.abs(offset)

      Card {
        animationDuration: cardDeck.animationDuration
        centerWidth: cardDeck.centerWidth
        filePath: cardDeck.filteredModel[card.modelIndex]?.filePath ?? ""
        isCenter: card.isCenter
        isVideo: cardDeck.filteredModel[card.modelIndex]?.isVideo ?? false
        radius: cardDeck.cardRadius
        thumbnailPath: cardDeck.filteredModel[card.modelIndex]?.thumbnail ?? ""
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: card.isCenter ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
          if (card.isCenter)
            cardDeck.applyRequested(card.modelIndex);
        }

        //
        onWheel: function (wheel) {
          if (wheel.angleDelta.y > 0)
            cardDeck.navigateTo(cardDeck.currentIndex - 1);
          else if (wheel.angleDelta.y < 0)
            cardDeck.navigateTo(cardDeck.currentIndex + 1);
        }
      }
    }
  }
}
