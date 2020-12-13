/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.components 1.0 as LatteComponents
import org.kde.latte.private.containment 0.1 as LatteContainment

import "../../controls" as LatteExtraControls

PlasmaComponents.Page {
    Layout.maximumWidth: content.width + content.Layout.leftMargin * 2
    Layout.maximumHeight: content.height + units.smallSpacing * 2

    ColumnLayout {
        id: content

        width: (dialog.appliedWidth - units.smallSpacing * 2) - Layout.leftMargin * 2
        spacing: dialog.subGroupSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        Layout.leftMargin: units.smallSpacing * 2

        //! BEGIN: Inline Dock/Panel Type, it is used only when the secondary window
        //! overlaps the main dock config window
        Loader {
            Layout.fillWidth: true
            active: dialog.advancedLevel && viewConfig.showInlineProperties && viewConfig.isReady
            visible: active

            sourceComponent: ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: units.smallSpacing
                spacing: units.smallSpacing

                LatteComponents.Header {
                    text: i18n("Type")
                }

                LatteExtraControls.TypeSelection{
                    id: viewTypeSelection
                    horizontal: true
                }
            }
        }
        //! END: Inline Dock/Panel Type

        //! BEGIN: Location
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing
            Layout.topMargin: units.smallSpacing

            LatteComponents.Header {
                text: screenRow.visible ? i18n("Screen") : i18n("Location")
            }

            Connections {
                target: universalSettings
                onScreensCountChanged: screenRow.updateScreens()
            }

            RowLayout {
                id: screenRow
                Layout.fillWidth: true
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 3
                spacing: 2
                visible: screensCount > 1 || dialog.advancedLevel

                property int screensCount: 1

                function updateScreens() {
                    screensCount = universalSettings.screens.length;
                    screensModel.clear();

                    var primary = {name: i18n("Follow Primary Screen"), icon: 'favorites'};
                    screensModel.append(primary);

                    //check if the screen exists, it is used in cases Latte is moving
                    //the view automatically to primaryScreen in order for the user
                    //to has always a view with tasks shown
                    var screenExists = false
                    for (var i = 0; i < universalSettings.screens.length; i++) {
                        if (universalSettings.screens[i].name === latteView.positioner.currentScreenName) {
                            screenExists = true;
                        }
                    }

                    if (!screenExists && !latteView.onPrimary) {
                        var scr = {name: latteView.positioner.currentScreenName, icon: 'view-fullscreen'};
                        screensModel.append(scr);
                    }

                    for (var i = 0; i < universalSettings.screens.length; i++) {
                        var scr = {name: universalSettings.screens[i].name, icon: 'view-fullscreen'};
                        screensModel.append(scr);
                    }

                    if (latteView.onPrimary) {
                        screenCmb.currentIndex = 0;
                    } else {
                        screenCmb.currentIndex = screenCmb.findScreen(latteView.positioner.currentScreenName);
                    }

                    console.log(latteView.positioner.currentScreenName);
                }

                Connections{
                    target: viewConfig
                    onShowSignal: screenRow.updateScreens();
                }

                ListModel {
                    id: screensModel
                }

                LatteComponents.ComboBox {
                    id: screenCmb
                    Layout.fillWidth: true
                    model: screensModel
                    textRole: "name"
                    iconRole: "icon"

                    Component.onCompleted: screenRow.updateScreens();

                    onActivated: {
                        var succeed = false;

                        if (index === 0) {
                            succeed = latteView.positioner.setCurrentScreen("primary");

                            if (succeed) {
                                latteView.onPrimary = true;
                            } else if (!latteView.onPrimary){
                                console.log("the edge is already occupied!!!");
                                currentIndex = findScreen(latteView.positioner.currentScreenName);
                            }
                        } else if (index>0 && (index !== findScreen(latteView.positioner.currentScreenName) || latteView.onPrimary)) {
                            console.log("current index changed!!! :"+ index);
                            console.log("screen must be changed...");

                            succeed = latteView.positioner.setCurrentScreen(textAt(index));

                            if(succeed) {
                                latteView.onPrimary = false;
                            } else {
                                console.log("the edge is already occupied!!!");
                                currentIndex = findScreen(latteView.positioner.currentScreenName);
                            }
                        }                        
                    }

                    function findScreen(scrName) {
                        for(var i=0; i<screensModel.count; ++i) {
                            if (screensModel.get(i).name === scrName) {
                                return i;
                            }
                        }

                        return 0;
                    }
                }
            }

            RowLayout {
                id: locationLayout
                Layout.fillWidth: true
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2
                Layout.topMargin: screenRow.visible ? units.smallSpacing : 0
                LayoutMirroring.enabled: false
                spacing: 2

                readonly property int buttonSize: (dialog.optionsWidth - (spacing * 3)) / 4

                ExclusiveGroup {
                    id: locationGroup
                }

                PlasmaComponents.Button {
                    id: bottomEdgeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18nc("bottom location", "Bottom")
                    iconSource: "arrow-down"
                    checked: plasmoid.location === edge
                    checkable: false
                    exclusiveGroup: locationGroup

                    readonly property int edge: PlasmaCore.Types.BottomEdge

                    onClicked: {
                        //! clicked event is more wayland friendly because it release focus from the button before hiding the window
                        if (viewConfig.isReady && plasmoid.location !== edge) {
                            latteView.positioner.hideDockDuringLocationChange(edge);
                        }
                    }
                }
                PlasmaComponents.Button {
                    id: leftEdgeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18nc("left location", "Left")
                    iconSource: "arrow-left"
                    checked: plasmoid.location === edge
                    checkable: false
                    exclusiveGroup: locationGroup

                    readonly property int edge: PlasmaCore.Types.LeftEdge

                    onClicked: {
                        //! clicked event is more wayland friendly because it release focus from the button before hiding the window
                        if (viewConfig.isReady && plasmoid.location !== edge) {
                            latteView.positioner.hideDockDuringLocationChange(edge);
                        }
                    }
                }
                PlasmaComponents.Button {
                    id: topEdgeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18nc("top location", "Top")
                    iconSource: "arrow-up"
                    checked: plasmoid.location === edge
                    checkable: false
                    exclusiveGroup: locationGroup

                    readonly property int edge: PlasmaCore.Types.TopEdge

                    onClicked: {
                        //! clicked event is more wayland friendly because it release focus from the button before hiding the window
                        if (viewConfig.isReady && plasmoid.location !== edge) {
                            latteView.positioner.hideDockDuringLocationChange(edge);
                        }
                    }
                }
                PlasmaComponents.Button {
                    id: rightEdgeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18nc("right location", "Right")
                    iconSource: "arrow-right"
                    checked: plasmoid.location === edge
                    checkable: false
                    exclusiveGroup: locationGroup

                    readonly property int edge: PlasmaCore.Types.RightEdge

                    onClicked: {
                        //! clicked event is more wayland friendly because it release focus from the button before hiding the window
                        if (viewConfig.isReady && plasmoid.location !== edge) {
                            latteView.positioner.hideDockDuringLocationChange(edge);
                        }
                    }
                }
            }
        }
        //! END: Location

        //! BEGIN: Alignment
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing

            LatteComponents.Header {
                text: i18n("Alignment")
            }

            RowLayout {
                id: alignmentRow
                Layout.fillWidth: true
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2
                LayoutMirroring.enabled: false
                spacing: 2

                readonly property int configAlignment: plasmoid.configuration.alignment
                readonly property int buttonSize: (dialog.optionsWidth - (spacing * 3)) / 4

                ExclusiveGroup {
                    id: alignmentGroup
                }

                PlasmaComponents.Button {
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: panelIsVertical ? i18nc("top alignment", "Top") : i18nc("left alignment", "Left")
                    iconSource: panelIsVertical ? "format-align-vertical-top" : "format-justify-left"
                    checked: parent.configAlignment === alignment
                    checkable: false
                    exclusiveGroup: alignmentGroup

                    property int alignment: panelIsVertical ? LatteCore.Types.Top : LatteCore.Types.Left

                    onPressedChanged: {
                        if (pressed) {
                            plasmoid.configuration.alignment = alignment
                        }
                    }
                }
                PlasmaComponents.Button {
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18nc("center alignment", "Center")
                    iconSource: panelIsVertical ? "format-align-vertical-center" : "format-justify-center"
                    checked: parent.configAlignment === alignment
                    checkable: false
                    exclusiveGroup: alignmentGroup

                    property int alignment: LatteCore.Types.Center

                    onPressedChanged: {
                        if (pressed) {
                            plasmoid.configuration.alignment = alignment
                        }
                    }
                }
                PlasmaComponents.Button {
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: panelIsVertical ? i18nc("bottom alignment", "Bottom") : i18nc("right alignment", "Right")
                    iconSource: panelIsVertical ? "format-align-vertical-bottom" : "format-justify-right"
                    checked: parent.configAlignment === alignment
                    checkable: false
                    exclusiveGroup: alignmentGroup

                    property int alignment: panelIsVertical ? LatteCore.Types.Bottom : LatteCore.Types.Right

                    onPressedChanged: {
                        if (pressed) {
                            plasmoid.configuration.alignment = alignment
                        }
                    }
                }

                PlasmaComponents.Button {
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18nc("justify alignment", "Justify")
                    iconSource: "format-justify-fill"
                    checked: parent.configAlignment === alignment
                    checkable: false
                    exclusiveGroup: alignmentGroup

                    property int alignment: LatteCore.Types.Justify

                    onPressedChanged: {
                        if (pressed) {
                            plasmoid.configuration.alignment = alignment
                        }
                    }
                }
            }
        }
        //! END: Alignment

        //! BEGIN: Visibility
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing

            LatteComponents.Header {
                text: i18n("Visibility")
            }

            GridLayout {
                width: parent.width
                rowSpacing: 1
                columnSpacing: 2
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2

                columns: 2

                property int mode: latteView.visibility.mode
                readonly property int buttonSize: (dialog.optionsWidth - (columnSpacing)) / 2

                ExclusiveGroup {
                    id: visibilityGroup
                }

                PlasmaComponents.Button {
                    id:alwaysVisibleBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18n("Always Visible")
                    checked: parent.mode === mode
                    checkable: false
                    exclusiveGroup: visibilityGroup

                    property int mode: LatteCore.Types.AlwaysVisible

                    onPressedChanged: {
                        if (pressed) {
                            latteView.visibility.mode = mode;
                        }
                    }
                }
                PlasmaComponents.Button {
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18n("Auto Hide")
                    checked: parent.mode === mode
                    checkable: false
                    exclusiveGroup: visibilityGroup

                    property int mode: LatteCore.Types.AutoHide

                    onPressedChanged: {
                        if (pressed) {
                            latteView.visibility.mode = mode;
                        }
                    }
                }
                PlasmaComponents.Button {
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    text: i18n("Dodge Active")
                    checked: parent.mode === mode
                    checkable: false
                    exclusiveGroup: visibilityGroup

                    property int mode: LatteCore.Types.DodgeActive

                    onPressedChanged: {
                        if (pressed) {
                            latteView.visibility.mode = mode;
                        }
                    }
                }

                LatteExtraControls.CustomVisibilityModeButton {
                    id: dodgeModeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    implicitWidth: alwaysVisibleBtn.implicitWidth
                    implicitHeight: alwaysVisibleBtn.implicitHeight

                    checked: parent.mode === mode
                    exclusiveGroup:  visibilityGroup

                    mode: plasmoid.configuration.lastDodgeVisibilityMode
                    modes: [
                        {
                            pluginId: LatteCore.Types.DodgeMaximized,
                            name: i18n("Dodge Maximized"),
                            tooltip: ""
                        },
                        {
                            pluginId: LatteCore.Types.DodgeAllWindows,
                            name: i18n("Dodge All Windows"),
                            tooltip: ""
                        }
                    ]

                    onViewRelevantVisibilityModeChanged: plasmoid.configuration.lastDodgeVisibilityMode = latteView.visibility.mode;
                }

                LatteExtraControls.CustomVisibilityModeButton {
                    id: windowsModeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    implicitWidth: alwaysVisibleBtn.implicitWidth
                    implicitHeight: alwaysVisibleBtn.implicitHeight

                    checked: parent.mode === mode
                    exclusiveGroup:  visibilityGroup

                    mode: plasmoid.configuration.lastWindowsVisibilityMode
                    modes: [
                        {
                            pluginId: LatteCore.Types.WindowsGoBelow,
                            name: i18n("Windows Go Below"),
                            tooltip: ""
                        },
                        {
                            pluginId: LatteCore.Types.WindowsCanCover,
                            name: i18n("Windows Can Cover"),
                            tooltip: ""
                        },
                        {
                            pluginId: LatteCore.Types.WindowsAlwaysCover,
                            name: i18n("Windows Always Cover"),
                            tooltip: ""
                        }
                    ]

                    onViewRelevantVisibilityModeChanged: plasmoid.configuration.lastWindowsVisibilityMode = latteView.visibility.mode;
                }

                LatteExtraControls.CustomVisibilityModeButton {
                    id: sidebarModeBtn
                    Layout.minimumWidth: parent.buttonSize
                    Layout.maximumWidth: Layout.minimumWidth
                    implicitWidth: alwaysVisibleBtn.implicitWidth
                    implicitHeight: alwaysVisibleBtn.implicitHeight

                    checked: parent.mode === mode
                    exclusiveGroup:  visibilityGroup

                    mode: plasmoid.configuration.lastSidebarVisibilityMode
                    modes: [
                        {
                            pluginId: LatteCore.Types.SidebarOnDemand,
                            name: i18n("On Demand Sidebar"),
                            tooltip: i18n("Sidebar can be shown and become hidden only through an external applet, shortcut or script")
                        },
                        {
                            pluginId: LatteCore.Types.SidebarAutoHide,
                            name: i18n("Auto Hide Sidebar"),
                            tooltip: i18n("Sidebar can be shown only through an external applet, shortcut or script but it can also autohide itself when it does not contain mouse")
                        }
                    ]

                    onViewRelevantVisibilityModeChanged: plasmoid.configuration.lastSidebarVisibilityMode = latteView.visibility.mode;
                }

            }
        }
        //! END: Visibility

        //! BEGIN: Delay
        ColumnLayout {
            Layout.fillWidth: true
            spacing: units.smallSpacing

            enabled: !(latteView.visibility.mode === LatteCore.Types.AlwaysVisible
                       || latteView.visibility.mode === LatteCore.Types.WindowsGoBelow
                       || latteView.visibility.mode === LatteCore.Types.WindowsAlwaysCover
                       || latteView.visibility.mode === LatteCore.Types.SidebarOnDemand)

            LatteComponents.Header {
                text: i18n("Delay")
            }

            Flow {
                width: dialog.optionsWidth
                Layout.minimumWidth: dialog.optionsWidth
                Layout.maximumWidth: dialog.optionsWidth
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2
                Layout.topMargin: units.smallSpacing

                spacing: 2

                readonly property bool overlap: showContainer.overlap || hideContainer.overlap

                Item {
                    id: showContainer
                    width: parent.overlap ? dialog.optionsWidth : oneLineWidth
                    height: childrenRect.height
                    implicitWidth: width
                    implicitHeight: height

                    readonly property bool overlap: oneLineWidth > alwaysVisibleBtn.width
                    readonly property int oneLineWidth: Math.max(alwaysVisibleBtn.width, showTimerRow.width)

                    RowLayout{
                        id: showTimerRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: latteView.visibility.mode !== LatteCore.Types.SidebarAutoHide
                        PlasmaComponents.Label {
                            Layout.leftMargin: Qt.application.layoutDirection === Qt.RightToLeft ? units.smallSpacing : 0
                            Layout.rightMargin: Qt.application.layoutDirection === Qt.RightToLeft ? 0 : units.smallSpacing
                            text: i18n("Show ")
                        }

                        LatteComponents.TextField {
                            Layout.preferredWidth: width
                            text: latteView.visibility.timerShow

                            onValueChanged: {
                                latteView.visibility.timerShow = value
                            }
                        }
                    }
                }

                Item {
                    id: hideContainer
                    width: parent.overlap ? dialog.optionsWidth : oneLineWidth
                    height: childrenRect.height
                    implicitWidth: width
                    implicitHeight: height

                    readonly property bool overlap: oneLineWidth > alwaysVisibleBtn.width
                    readonly property int oneLineWidth: Math.max(alwaysVisibleBtn.width, hideTimerRow.width)

                    RowLayout {
                        id: hideTimerRow
                        anchors.horizontalCenter: parent.horizontalCenter

                        PlasmaComponents.Label {
                            Layout.leftMargin: Qt.application.layoutDirection === Qt.RightToLeft ? units.smallSpacing : 0
                            Layout.rightMargin: Qt.application.layoutDirection === Qt.RightToLeft ? 0 : units.smallSpacing
                            text: i18n("Hide")
                        }

                        LatteComponents.TextField{
                            Layout.preferredWidth: width
                            text: latteView.visibility.timerHide
                            maxValue: 5000

                            onValueChanged: {
                                latteView.visibility.timerHide = value
                            }
                        }
                    }
                }
            }
        }
        //! END: Delay

        //! BEGIN: Actions
        ColumnLayout {
            spacing: units.smallSpacing
            visible: dialog.advancedLevel

            LatteComponents.Header {
                text: i18n("Actions")
            }

            ColumnLayout {
                id: actionsPropertiesColumn
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2
                spacing: 0

                readonly property int maxLabelWidth: Math.max(trackActiveLbl.implicitWidth,
                                                              mouseWheelLbl.implicitWidth,
                                                              leftBtnLbl.implicitWidth,
                                                              midBtnLbl.implicitWidth)

                LatteComponents.SubHeader {
                    text: i18n("Active Window")
                }

                ColumnLayout {
                    RowLayout {
                        Layout.topMargin: units.smallSpacing

                        PlasmaComponents.Label {
                            id: trackActiveLbl
                            Layout.minimumWidth: actionsPropertiesColumn.maxLabelWidth
                            Layout.maximumWidth: actionsPropertiesColumn.maxLabelWidth
                            text: i18n("Track From")
                        }

                        LatteComponents.ComboBox {
                            id: activeWindowFilterCmb
                            Layout.fillWidth: true
                            model: [i18nc("track from current screen", "Current Screen"),
                                i18nc("track from all screens", "All Screens")]

                            currentIndex: plasmoid.configuration.activeWindowFilter

                            onCurrentIndexChanged: {
                                switch(currentIndex) {
                                case LatteContainment.Types.ActiveInCurrentScreen:
                                    plasmoid.configuration.activeWindowFilter = LatteContainment.Types.ActiveInCurrentScreen;
                                    break;
                                case LatteContainment.Types.ActiveFromAllScreens:
                                    plasmoid.configuration.activeWindowFilter = LatteContainment.Types.ActiveFromAllScreens;
                                    break;
                                }
                            }
                        }
                    }
                }

                LatteComponents.SubHeader {
                    text: i18n("Empty Area")
                }

                ColumnLayout {
                    RowLayout {
                        PlasmaComponents.Label {
                            id: leftBtnLbl
                            Layout.minimumWidth: actionsPropertiesColumn.maxLabelWidth
                            Layout.maximumWidth: actionsPropertiesColumn.maxLabelWidth
                            text: i18n("Left Button")
                        }

                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: i18n("Drag Active Window")
                            checked: plasmoid.configuration.dragActiveWindowEnabled
                            checkable: true
                            tooltip: i18n("The user can use left mouse button to drag and maximized/restore last active window")
                            iconName: "transform-move"

                            onClicked: {
                                plasmoid.configuration.dragActiveWindowEnabled = !plasmoid.configuration.dragActiveWindowEnabled;
                            }
                        }
                    }

                    RowLayout {
                        PlasmaComponents.Label {
                            id: midBtnLbl
                            Layout.minimumWidth: actionsPropertiesColumn.maxLabelWidth
                            Layout.maximumWidth: actionsPropertiesColumn.maxLabelWidth
                            text: i18n("Middle Button")
                        }

                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: i18n("Close Active Window")
                            checked: plasmoid.configuration.closeActiveWindowEnabled
                            checkable: true
                            tooltip: i18n("The user can use middle mouse button to close last active window")
                            iconName: "window-close"

                            onClicked: {
                                plasmoid.configuration.closeActiveWindowEnabled = !plasmoid.configuration.closeActiveWindowEnabled;
                            }
                        }
                    }

                    RowLayout {
                       // Layout.topMargin: units.smallSpacing

                        PlasmaComponents.Label {
                            id: mouseWheelLbl
                            Layout.minimumWidth: actionsPropertiesColumn.maxLabelWidth
                            Layout.maximumWidth: actionsPropertiesColumn.maxLabelWidth
                            text: i18n("Mouse wheel")
                        }

                        LatteComponents.ComboBox {
                            id: scrollAction
                            Layout.fillWidth: true
                            model: [i18nc("none scroll actions", "None Action"),
                                i18n("Cycle Through Desktops"),
                                i18n("Cycle Through Activities"),
                                i18n("Cycle Through Tasks"),
                                i18n("Cycle And Minimize Tasks")
                            ]

                            currentIndex: plasmoid.configuration.scrollAction

                            onCurrentIndexChanged: {
                                switch(currentIndex) {
                                case LatteContainment.Types.ScrollNone:
                                    plasmoid.configuration.scrollAction = LatteContainment.Types.ScrollNone;
                                    break;
                                case LatteContainment.Types.ScrollDesktops:
                                    plasmoid.configuration.scrollAction = LatteContainment.Types.ScrollDesktops;
                                    break;
                                case LatteContainment.Types.ScrollActivities:
                                    plasmoid.configuration.scrollAction = LatteContainment.Types.ScrollActivities;
                                    break;
                                case LatteContainment.Types.ScrollTasks:
                                    plasmoid.configuration.scrollAction = LatteContainment.Types.ScrollTasks;
                                    break;
                                case LatteContainment.Types.ScrollToggleMinimized:
                                    plasmoid.configuration.scrollAction = LatteContainment.Types.ScrollToggleMinimized;
                                    break;
                                }
                            }
                        }
                    }
                }

                LatteComponents.SubHeader {
                    text: i18n("Items")
                }

                LatteComponents.CheckBoxesColumn {
                    LatteComponents.CheckBox {
                        id: titleTooltipsChk
                        Layout.maximumWidth: dialog.optionsWidth
                        text: i18n("Thin title tooltips on hovering")
                        tooltip: i18n("Show narrow tooltips produced by Latte for items.\nThese tooltips are not drawn when applets zoom effect is disabled");
                        checked: plasmoid.configuration.titleTooltips
                        enabled: latteView.type === LatteCore.Types.DockView

                        onClicked: {
                            plasmoid.configuration.titleTooltips = !plasmoid.configuration.titleTooltips;
                        }
                    }

                    LatteComponents.CheckBox {
                        id: mouseWheelChk
                        Layout.maximumWidth: dialog.optionsWidth
                        text: i18n("Expand popup through mouse wheel")
                        checked: plasmoid.configuration.mouseWheelActions
                        tooltip: i18n("Show or Hide applet popup through mouse wheel action")
                        visible: dialog.advancedLevel

                        onClicked: {
                            plasmoid.configuration.mouseWheelActions = !plasmoid.configuration.mouseWheelActions;
                        }
                    }

                    LatteComponents.CheckBox {
                        id: autoSizeChk
                        Layout.maximumWidth: dialog.optionsWidth
                        text: i18n("Adjust size automatically when needed")
                        checked: plasmoid.configuration.autoSizeEnabled
                        tooltip: i18n("Items decrease their size when exceed maximum length and increase it when they can fit in")
                        visible: dialog.advancedLevel
                        enabled: latteView.type === LatteCore.Types.DockView

                        onClicked: {
                            plasmoid.configuration.autoSizeEnabled = !plasmoid.configuration.autoSizeEnabled
                        }
                    }

                    LatteComponents.CheckBox {
                        Layout.maximumWidth: dialog.optionsWidth
                       // Layout.maximumHeight: mouseWheelChk.height
                        text: i18n("➊ Activate based on position global shortcuts")
                        checked: latteView.isPreferredForShortcuts || (!latteView.layout.preferredForShortcutsTouched && latteView.isHighestPriorityView())
                        tooltip: i18n("This view is used for based on position global shortcuts. Take note that only one view can have that option enabled for each layout")

                        onClicked: {
                            latteView.isPreferredForShortcuts = checked;
                            if (!latteView.layout.preferredForShortcutsTouched) {
                                latteView.layout.preferredForShortcutsTouched = true;
                            }
                        }
                    }
                }
            }

            LatteComponents.SubHeader {
                id: floatingSubCategory
                text: i18n("Floating")
                enabled: !plasmoid.configuration.shrinkThickMargins && (plasmoid.configuration.screenEdgeMargin >= 0)
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2
                enabled: floatingSubCategory.enabled

                LatteComponents.CheckBoxesColumn {
                    LatteComponents.CheckBox {
                        Layout.maximumWidth: dialog.optionsWidth
                        text: i18n("Always use floating gap for user interaction")
                        checkedState: plasmoid.configuration.floatingInternalGapIsForced
                        partiallyCheckedEnabled: true
                        tooltip: i18n("Floating gap is always used from applets and any relevant user interaction when \nthat option is enabled. Default option is auto selecting that behavior.")

                        onClicked: {
                            plasmoid.configuration.floatingInternalGapIsForced = checkedState;
                        }
                    }

                    LatteComponents.CheckBox {
                        Layout.maximumWidth: dialog.optionsWidth
                        text: i18n("Hide floating gap for maximized windows")
                        checked: plasmoid.configuration.hideFloatingGapForMaximized
                        tooltip: i18n("Floating gap is disabled when there are maximized windows")

                        onClicked: {
                            plasmoid.configuration.hideFloatingGapForMaximized = checked;
                        }
                    }
                }
            }
        }
        //! END: Actions

        //! BEGIN: Adjust
        ColumnLayout {
            spacing: units.smallSpacing

            visible: dialog.advancedLevel
            enabled: !(latteView.visibility.mode === LatteCore.Types.AlwaysVisible
                       || latteView.visibility.mode === LatteCore.Types.WindowsGoBelow
                       || latteView.visibility.mode === LatteCore.Types.WindowsCanCover
                       || latteView.visibility.mode === LatteCore.Types.WindowsAlwaysCover)

            LatteComponents.Header {
                text: i18n("Environment")
            }

            LatteComponents.CheckBoxesColumn {
                Layout.leftMargin: units.smallSpacing * 2
                Layout.rightMargin: units.smallSpacing * 2

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Activate KWin edge after hiding")
                    checked: latteView.visibility.enableKWinEdges
                    tooltip: i18n("After the view becomes hidden, KWin is informed to track user feedback. For example an edge visual hint is shown whenever the mouse approaches the hidden view")
                    enabled: !dialog.viewIsPanel
                             && !latteView.byPassWM
                             && latteView.visibility.mode !== LatteCore.Types.SidebarOnDemand
                             && latteView.visibility.mode !== LatteCore.Types.SidebarAutoHide

                    onClicked: {
                        latteView.visibility.enableKWinEdges = checked;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Can be above fullscreen windows")
                    checked: latteView.byPassWM

                    tooltip: i18n("BypassWindowManagerHint flag for the window. The view will be above all windows even those set as 'Always On Top'")

                    onCheckedChanged: {
                        latteView.byPassWM = checked;
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Raise on desktop change")
                    checked: latteView.visibility.raiseOnDesktop

                    onClicked: {
                        latteView.visibility.raiseOnDesktop = checked
                    }
                }

                LatteComponents.CheckBox {
                    Layout.maximumWidth: dialog.optionsWidth
                    text: i18n("Raise on activity change")
                    checked: latteView.visibility.raiseOnActivity

                    onClicked: {
                        latteView.visibility.raiseOnActivity = checked
                    }
                }
            }
        }
        //! END: Adjust

    }
}
