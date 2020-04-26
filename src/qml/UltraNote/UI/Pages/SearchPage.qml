import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import QtQuick.Layouts 1.13

import UltraNote.UI 1.0
import UltraNote.UI.Controls 1.0
import UltraNote.SearchService 1.0

UNPage {
    id: _page

    objectName: "search_page"

    title: qsTr("Search")

    contentItem: Item {
        anchors.fill: parent

        ColumnLayout {
            id: _pageContent

            anchors.fill: parent

            spacing: 0

            UNLayoutSpacer {
                fixedHeight: 24
            }

            UNLabel {
                Layout.preferredHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.minimumHeight: implicitHeight
                Layout.fillWidth: true

                type: UNLabel.Type.TypePageSubcategoryTitle

                size: 24
                color: Theme.secondaryColor
                horizontalAlignment: Label.AlignHCenter
                text: qsTr("UltraSearch Anonymous Search")
            }

            UNLayoutSpacer {
                fixedHeight: 24
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.maximumHeight: 48
                Layout.minimumHeight: 48
                Layout.leftMargin: 48
                Layout.rightMargin: 48

                spacing: 24

                UNTextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onEnterPressed: {
                        console.log("Enter key pressed. Starting search...")
                        _searchButton.onClicked()
                    }

                    onTextChanged: {
                        walletAdapter.searchService.searchText = text
                    }
                }

                UNButton {
                    id: _searchButton

                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    Layout.fillHeight: true

                    text: qsTr("Search")

                    onClicked: {
                        walletAdapter.searchService.startSearch()
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 24
            }

            ListView {
                id: _searchTypeListView

                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40
                Layout.preferredWidth: contentWidth
                Layout.maximumWidth: contentWidth
                Layout.minimumWidth: contentWidth
                Layout.alignment: Qt.AlignHCenter

                model: ListModel {
                    ListElement { text: qsTr("All") }
                    ListElement { text: qsTr("Images") }
                    ListElement { text: qsTr("News") }
                }

                interactive: false
                orientation: Qt.Horizontal

                spacing: 48

                delegate: UNRadioButton {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth

                    text: model.text

                    autoExclusive: true
                    checked: index === _searchTypeListView.currentIndex

                    onClicked: {
                        switch(index) {
                        case 0:
                            walletAdapter.searchService.searchType = SearchServiceSearchType.ALL
                            break;
                        case 1:
                            walletAdapter.searchService.searchType = SearchServiceSearchType.IMAGES
                            break;
                        case 2:
                            walletAdapter.searchService.searchType = SearchServiceSearchType.NEWS
                            break;
                        default:
                            walletAdapter.searchService.searchType = SearchServiceSearchType.ALL
                        }
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 24
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 16
                Layout.rightMargin: 8

                sourceComponent: walletAdapter.searchService.progress.toString() === "IN_PROGRESS" ? _searchWaitComponent
                                                                                                   : _searchResultsComponent

                Component {
                    id: _searchWaitComponent

                    Item {
                        BusyIndicator {
                            anchors.centerIn: parent

                            }
                    }
                }

                Component {
                    id: _searchResultsComponent

                    ListView {
                        id: _searchResultsListView

                        model: walletAdapter.searchService.resultsModel

                        clip: true

                        spacing: 24

                        boundsBehavior: Flickable.StopAtBounds

                        ScrollIndicator.vertical: ScrollIndicator {
                            orientation: Qt.Vertical
                            visible: _searchResultsListView.height < _searchResultsListView.contentHeight
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

                        delegate: Item {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.rightMargin: 8

                            height: _searchResultsTextViewDelegate.height + 32

                            Rectangle {
                                id: _searchResultsTextViewDelegateBackground

                                anchors.fill: parent

                                color: Theme.searchResultBackgroundColor

                                border.width: 1

                                border.color: Theme.searchResultBackgroundBorder
                            }

                            TextEdit {
                                id: _searchResultsTextViewDelegate

                                property string urlHovered: ""

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16

                                height: implicitHeight

                                textFormat: TextEdit.RichText
                                wrapMode: TextEdit.WordWrap

                                font.family: UNFontsFactory.workSansRegular.name
                                font.pixelSize: 16

                                text: modelData

                                color: Theme.searchResultTextColor

                                MouseArea {
                                    anchors.fill: parent

                                    propagateComposedEvents: true
                                    preventStealing: false

                                    hoverEnabled: true

                                    cursorShape: _searchResultsTextViewDelegate.urlHovered.length > 0 ? Qt.PointingHandCursor
                                                                                                      : Qt.ArrowCursor

                                    onMouseXChanged: {
                                        _searchResultsTextViewDelegate.urlHovered = _searchResultsTextViewDelegate.linkAt(mouseX, mouseY)
                                    }

                                    onMouseYChanged: {
                                        _searchResultsTextViewDelegate.urlHovered = _searchResultsTextViewDelegate.linkAt(mouseX, mouseY)
                                    }

                                    onClicked: {
                                        if(_searchResultsTextViewDelegate.urlHovered.length > 0) {
                                            Qt.openUrlExternally(Qt.resolvedUrl(_searchResultsTextViewDelegate.urlHovered))
                                        }
                                    }
                                }
                            }

                        }
                    }
                }
            }

            UNLayoutSpacer {
                fixedHeight: 24
            }
        }

    }

    Connections {
        target: walletAdapter.searchService

        onProgressChanged: {
            switch(walletAdapter.searchService.progress.toString()) {
            case "ERROR":
                _messageDialogProperties.showMessage(qsTr("Error"), qsTr("No results found."))
                break;
            case "SUCCESS":
                _messageDialogProperties.showMessage(qsTr("Success"), qsTr("Your search is completed, Thank you for using UltraSearch!"))
                break;
            }
        }
    }
}
