import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

Dialog {
    id: _itm

    anchors.centerIn: parent

    property int maximumContentSize: _privateProperties.defaultMaximumContentSize
    property alias buttonContainer: _buttonBoxItem
    property color overlayColor: _privateProperties.defaultOverlayColor
    property color dialogBackgroundColor: Theme.dialogBackgroundColor
    property color dialogTitleTextColor: Theme.dialogTitleTextColor
    property bool  headerAlignmentCenter: false
    property alias buttons: _buttonsBox.model

    signal accepted()
    signal rejected()
    signal help()

    implicitWidth: 200

    height: implicitHeight
    width: implicitWidth

    spacing: 20

    modal: true

    QtObject {
        id: _privateProperties

        readonly property int defaultMaximumContentSize: 400
        readonly property color defaultOverlayColor: "#232f34"
    }

    //Visual type for control buttons
    enum ButtonType {
        TypeNormal,
        TypeFlat
    }

    enter: Transition {
        NumberAnimation { property: "scale"; from: 0.5; to: 1.0; easing.type: Easing.OutQuint; duration: 150 }
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; easing.type: Easing.OutCubic; duration: 150 }
    }

    exit: Transition {
        NumberAnimation { property: "scale"; from: 1.0; to: 0.8; easing.type: Easing.OutQuint; duration: 100 }
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; easing.type: Easing.OutCubic; duration: 100 }
    }


    background: UNElevatedPanel {
        id: _background

        anchors.fill: parent

        radius: 4

        elevation: 24

        color: _itm.dialogBackgroundColor
    }

    header: UNLabel {
        id: _header

        leftPadding: 30
        rightPadding: 30
        topPadding: 30

        type: UNLabel.Type.TypeDialogTitle
        color: _itm.dialogTitleTextColor
        text: _itm.title
        wrapMode: Label.WordWrap
        elide: Label.ElideNone
        horizontalAlignment: _itm.headerAlignmentCenter? Label.AlignHCenter : Label.AlignLeft
    }

    footer: Item {
        id: _buttonBoxItem

        height: 60
        implicitHeight: height

        ListView {
            id: _buttonsBox

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            orientation: ListView.Horizontal
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            spacing: 8
            layoutDirection: Qt.RightToLeft

            delegate: Loader {
                id: _buttonLoader

                anchors.verticalCenter: parent.verticalCenter

                height: 40
                width: 130

                sourceComponent: _flatButtonComponent

                onLoaded: {
                    item.clicked.connect(function() {
                        switch (model.role) {
                        case DialogButtonBox.AcceptRole:
                            _itm.accepted()
                            break;
                        case DialogButtonBox.RejectRole:
                            _itm.rejected()
                            break;
                        case DialogButtonBox.HelpRole:
                            _itm.help()
                            break;
                        }
                        _itm.close()
                    });
                    item.text = model.text

                    _buttonLoader.width = item.implicitWidth
                }

                Component {
                    id: _flatButtonComponent

                    Button {
                        id: _flatButton

                        anchors.centerIn: parent

                        width: _text.implicitWidth + (2 * 16)
                        implicitWidth: width

                        background: Item { }

                        contentItem: UNLabel {
                            id: _text

                            anchors.centerIn: parent

                            color: Theme.dialogActionButtonColor
                            text: _flatButton.text
                            type: UNLabel.Type.TypeDialogButton
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    Overlay.modal: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: 10

            color: Qt.rgba(_itm.overlayColor.r, _itm.overlayColor.g, _itm.overlayColor.b, 0.32)

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
