import qs.Commons
import qs.Widgets
import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
  id: cardContent

  required property int animationDuration
  required property real centerWidth
  required property string filePath
  required property bool isCenter
  required property bool isVideo
  required property real radius
  required property string thumbnailPath

  anchors.fill: parent
  clip: true

  Item {
    id: imgComposite

    height: cardContent.height
    visible: false
    width: cardContent.centerWidth
    x: (cardContent.width - cardContent.centerWidth) / 2

    Image {
      id: img

      anchors.fill: parent
      // asynchronous: true  // TODO: flickering when going backwards
      cache: true
      fillMode: Image.PreserveAspectCrop
      smooth: true
      source: cardContent.thumbnailPath ? "file://" + cardContent.thumbnailPath : ""
      sourceSize.height: parent.height
      sourceSize.width: cardContent.centerWidth
    }
  }

  Rectangle {
    id: border

    anchors.fill: parent
    border.color: isCenter ? Color.mOutline : Qt.alpha(Color.mOutlineVariant, 0.5)
    border.width: Style.borderS
    color: "transparent"
    opacity: 0.75
    radius: cardContent.radius
    z: 20
  }

  Rectangle {
    id: mask

    anchors.fill: parent
    radius: cardContent.radius
    visible: false
  }

  OpacityMask {
    anchors.fill: parent
    maskSource: mask

    source: ShaderEffectSource {
      sourceItem: imgComposite
      sourceRect: Qt.rect(-imgComposite.x, 0, cardContent.width, cardContent.height)
    }
  }

  Loader {
    id: videoLoader

    property bool shouldLoad: false
    property string videoPath: cardContent.isCenter && cardContent.isVideo ? cardContent.filePath : ""

    active: shouldLoad && videoPath !== ""
    anchors.fill: parent
    z: 5

    sourceComponent: Component {
      Item {
        id: videoContainer

        anchors.fill: parent
        layer.enabled: true
        opacity: 0

        layer.effect: OpacityMask {
          maskSource: Rectangle {
            height: videoContainer.height
            radius: cardContent.radius
            width: videoContainer.width
          }
        }

        MediaPlayer {
          id: mediaPlayer

          loops: MediaPlayer.Infinite
          source: "file://" + videoLoader.videoPath
          videoOutput: videoOutput

          audioOutput: AudioOutput {
            volume: 0
          }

          Component.onCompleted: play()
          onPlayingChanged: function () {
            if (mediaPlayer.playing)
              videoFadeIn.start();
          }
        }

        VideoOutput {
          id: videoOutput

          anchors.fill: parent
          fillMode: VideoOutput.PreserveAspectCrop
        }

        NumberAnimation {
          id: videoFadeIn

          duration: cardContent.animationDuration
          easing.type: Easing.OutCubic
          from: 0
          property: "opacity"
          target: videoContainer
          to: 1
        }
      }
    }

    onVideoPathChanged: {
      shouldLoad = false;
      if (videoPath !== "")
        videoDelayTimer.restart();
      else
        videoDelayTimer.stop();
    }

    Timer {
      id: videoDelayTimer

      interval: cardContent.animationDuration

      onTriggered: videoLoader.shouldLoad = true
    }
  }
}
