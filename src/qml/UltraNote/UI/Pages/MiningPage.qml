import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13
import Qt.labs.qmlmodels 1.0

import QrImage 1.0
import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0

UNPage {
    id: _page
    objectName: "mining_page"
    title: qsTr("Mining")

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
            id: _pageContent

            anchors.fill: parent
            anchors.rightMargin: 16

            spacing: 0

            property int labelTextWidth: Math.max(
                                             _selectPoolLabel.implicitWidth,
                                             _cpuCoresLabel.implicitWidth,
                                             _miningStatusLabel.implicitWidth)

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                spacing: 16

                UNLabel {
                    id: _selectPoolLabel

                    Layout.preferredWidth: _pageContent.labelTextWidth
                    Layout.maximumWidth: _pageContent.labelTextWidth
                    Layout.minimumWidth: _pageContent.labelTextWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypePageSubcategoryTitle
                    color: Theme.textColor

                    text: qsTr("Select Pool:")
                    verticalAlignment: Text.AlignVCenter
                }

                ComboBox {
                    Layout.preferredWidth: 250
                    Layout.maximumWidth: 250
                    Layout.minimumWidth: 250

                    enabled: !walletAdapter.miningService.isActive

                    model: walletAdapter.miningService.poolModel
                    currentIndex: walletAdapter.miningService.poolIndex

                    textRole: "display"

                    onCurrentTextChanged: {
                        walletAdapter.miningService.poolIndex = currentIndex
                    }
                }

                UNLayoutSpacer{}

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth

                    enabled: !walletAdapter.miningService.isActive

                    text: qsTr("Add Pool")

                    onClicked: {
                        walletAdapter.miningService.addPoolClicked()
                    }
                }

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth

                    enabled: !walletAdapter.miningService.isActive

                    text: qsTr("DefaultPools")

                    onClicked: {
                        walletAdapter.miningService.clearPoolsClicked()
                    }
                }

                UNLayoutSpacer {
                    fixedWidth: 16
                }
            }

            UNLayoutSpacer{
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                spacing: 16

                UNLabel {
                    id: _cpuCoresLabel

                    Layout.preferredWidth: _pageContent.labelTextWidth
                    Layout.maximumWidth: _pageContent.labelTextWidth
                    Layout.minimumWidth: _pageContent.labelTextWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypePageSubcategoryTitle
                    color: Theme.textColor

                    text: qsTr("Cpu Cores:")
                    verticalAlignment: Text.AlignVCenter
                }

                ComboBox {
                    id: _coreCountComboBox

                    Layout.preferredWidth: 250
                    Layout.maximumWidth: 250
                    Layout.minimumWidth: 250

                    enabled: !walletAdapter.miningService.isActive

                    model: _coreModel

                    currentIndex: walletAdapter.miningService.coreCount - 1

                    ListModel {
                        id: _coreModel

                        Component.onCompleted: {
                            for(var i = 0; i < walletAdapter.miningService.maxCoreCount; i++) {
                                _coreModel.append({"text": i + 1})
                            }

                            _coreCountComboBox.update()
                        }
                    }

                    onActivated: {
                        walletAdapter.miningService.coreCount = index + 1
                    }
                }

                UNLayoutSpacer{}
            }

            UNLayoutSpacer{
                fixedHeight: 16
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                UNCheckBox {
                    id: _scheduleCheckbox

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40

                    enabled: !walletAdapter.miningService.isActive

                    text: qsTr("Enable Mining Schedule")
                    checked: walletAdapter.miningService.cronEnabled

                    labelTextSize: Theme.miningCheckBoxTextColor

                    onClicked: {
                        walletAdapter.miningService.cronEnabled = checked
                    }
                }
            }

            UNLayoutSpacer{
                fixedHeight: 16
                visible: _scheduleCheckbox.checked
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                Layout.maximumHeight: 280
                Layout.minimumHeight: 280

                visible: _scheduleCheckbox.checked

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    height: 1

                    color: "white"
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    height: 1

                    color: "white"
                }

                ListView {
                    id: _content
                    anchors.fill: parent
                    anchors.topMargin: 20
                    anchors.bottomMargin: 20

                    clip: true

                    spacing: 16

                    model: walletAdapter.miningService.cronDataModel

                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        orientation: Qt.Vertical
                        visible: true
                        background: Item {}

                        contentItem: Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter

                            height: 200
                            implicitWidth: 4
                            implicitHeight: 200
                            radius: width / 2

                            color: Theme.scrollIndicatorColor
                        }
                    }

                    delegate: RowLayout {
                        id: delegate

                        anchors.left: parent.left
                        anchors.right: parent.right

                        height: 48

                        spacing: 16

                        UNLabel {
                            Layout.preferredWidth: 200
                            Layout.maximumWidth: 200
                            Layout.minimumWidth: 200
                            Layout.fillHeight: true

                            type: UNLabel.Type.TypeNormal

                            color: "white"

                            text: cron_data.label
                            verticalAlignment: Text.AlignVCenter
                        }

                        ComboBox {
                            Layout.preferredWidth: 150
                            Layout.maximumWidth: 150
                            Layout.minimumWidth: 150
                            Layout.alignment: Qt.AlignVCenter

                            enabled: false

                            model: [ qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thursday"), qsTr("Friday"), qsTr("Saturday"), qsTr("Sunday")]
                            currentIndex: cron_data.day
                        }

                        UNTextField {
                            Layout.preferredWidth: 70
                            Layout.maximumWidth: 70
                            Layout.minimumWidth: 70
                            Layout.alignment: Qt.AlignVCenter

                            horizontalAlignment: TextField.AlignHCenter

                            enabled: false

                            text: cron_data.startTime
                        }

                        UNTextField {
                            Layout.preferredWidth: 70
                            Layout.maximumWidth: 70
                            Layout.minimumWidth: 70
                            Layout.alignment: Qt.AlignVCenter

                            horizontalAlignment: TextField.AlignHCenter

                            enabled: false

                            text: cron_data.endTime
                        }

                        UNButton {
                            Layout.preferredWidth: implicitWidth
                            Layout.maximumWidth: implicitWidth
                            Layout.minimumWidth: implicitWidth
                            Layout.alignment: Qt.AlignVCenter
                            text: qsTr("Remove")

                            enabled: !walletAdapter.miningService.isActive

                            onClicked: {
                                walletAdapter.miningService.cronDataModel.removePattern(index)
                            }
                        }

                        UNLayoutSpacer {}
                    }
                }
            }

            UNLayoutSpacer{
                fixedHeight: 16
            }

            RowLayout {
                id: _addLayout

                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                spacing: 16

                visible: _scheduleCheckbox.checked

                UNTextField {
                    id: _addLabel

                    Layout.preferredWidth: 200
                    Layout.maximumWidth: 200
                    Layout.minimumWidth: 200
                    Layout.fillHeight: true

                    enabled: !walletAdapter.miningService.isActive

                    text: ""
                }

                ComboBox {
                    id: _addDay
                    Layout.preferredWidth: 150
                    Layout.maximumWidth: 150
                    Layout.minimumWidth: 150

                    enabled: !walletAdapter.miningService.isActive

                    model: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                }

                UNTextField {
                    id: _addStartTime

                    Layout.preferredWidth: 70
                    Layout.maximumWidth: 70
                    Layout.minimumWidth: 70
                    Layout.fillHeight: true

                    enabled: !walletAdapter.miningService.isActive

                    horizontalAlignment: TextField.AlignHCenter

                    text: "00:00"
                }

                UNTextField {
                    id: _addEndTime

                    Layout.preferredWidth: 70
                    Layout.maximumWidth: 70
                    Layout.minimumWidth: 70
                    Layout.fillHeight: true

                    enabled: !walletAdapter.miningService.isActive

                    horizontalAlignment: TextField.AlignHCenter

                    text: "00:00"
                }

                UNButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    text: qsTr("Add")

                    enabled: !walletAdapter.miningService.isActive

                    onClicked: {
                        var error = false
                        var errorMessage = qsTr("Please, fill the required data: \n")

                        if(_addLabel.text.length === 0) {
                            errorMessage += qsTr(" - Schedule label is empty\n")
                            error = true
                        }

                        if(_addEndTime.text < _addStartTime.text) {
                            errorMessage += qsTr(" - Schedule stop time should be greater than start time\n")
                            error = true
                        }

                        if(error) {
                            _messageDialogProperties.acceptCallback = null
                            _messageDialogProperties.showMessage(qsTr("Input data error"), errorMessage)
                            return
                        }

                        walletAdapter.miningService.cronDataModel.addPattern(_addLabel.text, _addStartTime.text, _addEndTime.text, _addDay.currentIndex)
                    }
                }

                UNLayoutSpacer {}
            }

            UNLayoutSpacer {}

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                spacing: 16

                UNLabel {
                    id: _miningStatusLabel

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypePageSubcategoryTitle
                    color: Theme.textColor

                    text: qsTr("Mining Status:")
                    verticalAlignment: Text.AlignVCenter
                }

                UNLabel {
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter

                    type: UNLabel.Type.TypePageSubcategoryTitle
                    color: Theme.textColor

                    text: walletAdapter.miningService.status
                    verticalAlignment: Label.AlignVCenter
                    horizontalAlignment: Label.AlignLeft
                    wrapMode: Label.WordWrap
                }

                UNLayoutSpacer {}
            }

            UNLayoutSpacer {
                fixedHeight: 16
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40

                UNButton {
                    text: qsTr("Start Mining")

                    enabled: !walletAdapter.miningService.isActive

                    onClicked: {
                        walletAdapter.miningService.startClicked()
                    }
                }

                UNButton {
                    text: qsTr("Stop Mining")

                    enabled: walletAdapter.miningService.isActive

                    onClicked: {
                        walletAdapter.miningService.stopClicked()
                    }
                }

                UNLayoutSpacer {}
            }
        }

    }

    Connections {
        target: walletAdapter.miningService
        onMaxCoreCountChanged: {
            console.log("Max core: " + walletAdapter.miningService.maxCoreCount)
            _coreModel.clear()

            for(var i = 0; i < walletAdapter.miningService.maxCoreCount; i++) {
                _coreModel.append({"text": i + 1})
            }

            _coreCountComboBox.update()
        }
    }
}
