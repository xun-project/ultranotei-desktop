pragma Singleton

import QtQuick 2.12

QtObject {
    id: fonts

    //Roboto Font

    readonly property FontLoader robotoRegular: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Regular.ttf"
    }

    readonly property FontLoader robotoBlack: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Black.ttf"
    }

    readonly property FontLoader robotoBlackItalic: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-BlackItalic.ttf"
    }

    readonly property FontLoader robotoBold: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Bold.ttf"
    }

    readonly property FontLoader robotoBoldItalic: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-BoldItalic.ttf"
    }

    readonly property FontLoader robotoItalic: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Italic.ttf"
    }

    readonly property FontLoader robotoLight: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Light.ttf"
    }

    readonly property FontLoader robotoLightItalic: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-LightItalic.ttf"
    }

    readonly property FontLoader robotoMedium: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Medium.ttf"
    }

    readonly property FontLoader robotoMediumItalic: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-MediumItalic.ttf"
    }

    readonly property FontLoader robotoThin: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-Thin.ttf"
    }

    readonly property FontLoader robotoThinItalic: FontLoader {
        source: "qrc:/fonts/resources/fonts/Roboto/Roboto-ThinItalic.ttf"
    }

    //Work Sans font

    readonly property FontLoader workSansBlack: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-Black.ttf"
    }

    readonly property FontLoader workSansBold: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-Bold.ttf"
    }

    readonly property FontLoader workSansExtraBold: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-ExtraBold.ttf"
    }

    readonly property FontLoader workSansExtraLight: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-ExtraLight.ttf"
    }

    readonly property FontLoader workSansLight: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-Light.ttf"
    }

    readonly property FontLoader workSansMedium: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-Medium.ttf"
    }

    readonly property FontLoader workSansRegular: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-Regular.ttf"
    }

    readonly property FontLoader workSansSemiBold: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-SemiBold.ttf"
    }

    readonly property FontLoader workSansThin: FontLoader {
        source: "qrc:/fonts/resources/fonts/Work Sans/WorkSans-Thin.ttf"
    }
}
