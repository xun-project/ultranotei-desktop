import QtQuick 2.13
import QtQuick.Controls 2.13

import UltraNote.UI.Controls 1.0

TextEdit {
    id: _itm

    enum Type {
        TypeNormal,
        TypeBold,
        TypeMedium,
        TypeExtraBold,
        TypeCheckbox,
        TypeRadioButton,
        TypePushButton,
        TypeFlatPushButton,
        TypeCardItemLabel,
        TypeFlatTextField,
        TypeTextField,
        TypeTableViewHeader,
        TypeFocusTypeDescriptionHeader,
        TypeTimeSpanLabel,
        TypePageIndicatorLabelCurrentIndex,
        TypePageIndicatorLabelCount,
        TypeDropdownListItem,
        TypeComboBox,
        TypeSpinBox,
        TypeDialogTitle,
        TypeDialogButton,
        TypeLinkLabel,
        TypeHelperCounter,
        TypeDrawerMainActionButton,
        TypeDrawerListItem,
        TypePageSubcategoryTitle
    }

    property var type: UNLabel.Type.Normal
    property int size : _privateProperties.sizeByType(type)

    QtObject {
        id: _privateProperties

        readonly property color defaultColor: "#161616"
        readonly property int defaultSize: 22

        function familyByType(type) {
            switch(type) {
            case UNLabel.Type.TypeFlatPushButton:
            case UNLabel.Type.TypeFlatTextField:
            case UNLabel.Type.TypeTextField:
            case UNLabel.Type.TypeTableViewHeader:
            case UNLabel.Type.TypeCheckbox:

            case UNLabel.Type.TypeTimeSpanLabel:
            case UNLabel.Type.TypeDropdownListItem:
            case UNLabel.Type.TypeComboBox:
                return UNFontsFactory.robotoRegular.name
            case UNLabel.Type.TypeFocusTypeDescriptionHeader:
            case UNLabel.Type.TypeCardItemLabel:
                return UNFontsFactory.robotoRegular.name
            case UNLabel.Type.TypePageIndicatorLabelCurrentIndex:
            case UNLabel.Type.TypePageIndicatorLabelCount:
            case UNLabel.Type.TypeSpinBox:
            case UNLabel.Type.TypeLinkLabel:
            case UNLabel.Type.TypeHelperCounter:
            case UNLabel.Type.TypePushButton:
            case UNLabel.Type.TypeBold:
                return UNFontsFactory.robotoBold.name
            case UNLabel.Type.TypeNormal:
            case UNLabel.Type.TypeRadioButton:
                return UNFontsFactory.workSansRegular.name
            case UNLabel.Type.TypeDrawerListItem:
            case UNLabel.Type.TypeMedium:
                return UNFontsFactory.workSansMedium.name
            case UNLabel.Type.TypeDialogButton:
                return UNFontsFactory.workSansSemiBold.name
            case UNLabel.Type.TypePageSubcategoryTitle:
            case UNLabel.Type.TypeDialogTitle:
                return UNFontsFactory.workSansBold.name
            case UNLabel.Type.TypeExtraBold:
            case UNLabel.Type.TypeDrawerMainActionButton:
                return UNFontsFactory.workSansExtraBold.name
            }
        }

        function sizeByType(type) {
            switch(type) {
            case UNLabel.Type.TypeCardItemLabel:
                return 16;
            case UNLabel.Type.TypeNormal:
            case UNLabel.Type.TypeBold:
            case UNLabel.Type.TypeMedium:
            case UNLabel.Type.TypeExtraBold:
                return 14;
            case UNLabel.Type.TypePushButton:
                return 14;
            case UNLabel.Type.TypeFlatTextField:
                return 10;
            case UNLabel.Type.TypeTextField:
                return 18;
            case UNLabel.Type.TypeTableViewHeader:
                return 12;
            case UNLabel.Type.TypeCheckbox:
                return 14
            case UNLabel.Type.TypeRadioButton:
                return 16
            case UNLabel.Type.TypeFocusTypeDescriptionHeader:
                return 18
            case UNLabel.Type.TypeTimeSpanLabel:
                return 11
            case UNLabel.Type.TypePageIndicatorLabelCurrentIndex:
                return 21
            case UNLabel.Type.TypePageIndicatorLabelCount:
                return 16
            case UNLabel.Type.TypeDropdownListItem:
                return 14
            case UNLabel.Type.TypeComboBox:
                return 14
            case UNLabel.Type.TypeSpinBox:
                return 16
            case UNLabel.Type.TypeDialogTitle:
                return 21
            case UNLabel.Type.TypeLinkLabel:
                return 15
            case UNLabel.Type.TypeHelperCounter:
                return 33
            case UNLabel.Type.TypeDrawerMainActionButton:
                return 16
            case UNLabel.Type.TypeDrawerListItem:
                return 16
            case UNLabel.Type.TypePageSubcategoryTitle:
                return 18
            case UNLabel.Type.TypeDialogButton:
                return 15
            }
        }

        function capsByType(type) {
            switch(type) {
            case UNLabel.Type.TypeTableViewHeader:
                return Font.AllUppercase
            default:
                return Font.MixedCase;
            }
        }
    }

    readOnly: true
    selectByMouse: true
    font.family: _privateProperties.familyByType(_itm.type);
    font.pixelSize: _itm.size === 0 ? _privateProperties.sizeByType(_itm.type) : _itm.size;
    font.capitalization: _privateProperties.capsByType(type);
    color: _privateProperties.defaultColor
    //lineHeightMode: Label.FixedHeight
    //lineHeight: font.pixelSize
    textFormat: TextEdit.RichText
    verticalAlignment: Label.AlignVCenter
}
