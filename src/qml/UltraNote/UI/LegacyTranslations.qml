import QtQuick 2.13
import QtQuick.Controls.Material 2.13

pragma Singleton

QtObject {

    //Mining page LegacyTranslations
    readonly property var minningStatus:
        [qsTr("Started")
        ,qsTr("Stopped")
        ,qsTr("Hashrate: %1 H/s")
        ,qsTr("Waiting for the schedule...")
        ,qsTr("Error: %1")]

    readonly property var addressBookTableHeaders:
        [qsTr("Label")
        ,qsTr("Address")]

    readonly property var messagesTableHeaders:
        [qsTr("Date")
        ,qsTr("Type")
        ,qsTr("Height")
        ,qsTr("Message")]

    readonly property var transactionsTableHeaders:
        [qsTr("Date")
        ,qsTr("Amount")
        ,qsTr("Address")
        ,qsTr("Message")
        ,qsTr("PaymentId")]

    readonly property var depositTableHeaders:
        [qsTr("Status")
        ,qsTr("Amount")
        ,qsTr("Interest")
        ,qsTr("Sum")
        ,qsTr("Rate")
        ,qsTr("UnlockHeight")
        ,qsTr("UnlockTime")
        ,qsTr("SpendingTime")]
}
