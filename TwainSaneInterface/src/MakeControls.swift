import MissingQD


class MakeControls {

    // typedef String(* CreateValueTextProc) (ControlRef control, value: Int)



    let valueFieldChangedEvent: EventTypeSpec = [ [ kEventClassControl,
                                                            kEventControlValueFieldChanged ] ]
    let controlHitEvent: EventTypeSpec        = [ [ kEventClassControl, kEventControlHit ] ]


    public func MakeStaticTextControl(parent: ControlRef, bounds: Rect, text: String,
                                    just: Int, small: Bool) -> ControlRef {

        var osstat: OSStatus
        var oserr: OSErr

        bounds.bottom = bounds.top + 16

        ControlFontStyleRec style
        style.flags = kControlUseFontMask | kControlUseJustMask
        style.font = (small ? kControlFontSmallSystemFont : kControlFontBigSystemFont)
        style.just = just

        ControlRef control
        osstat = CreateStaticTextControl(nil, bounds, text, &style, &control)
        assert(osstat == noErr)

        Int baseLineOffset
        oserr = GetBestControlRect(control, bounds, &baseLineOffset)
        assert(oserr == noErr)
        SetControlBounds(control, bounds)

        oserr = EmbedControl(control, parent)
        assert(oserr == noErr)

        return control
    }


    public func MakeButtonControl(parent: ControlRef, bounds: Rect, text: String,
                                command: Int, right: Bool, helptext: String, refcon: Int) -> ControlRef {

        var osstat: OSStatus
        var oserr: OSErr

        Rect controlrect

        if(right) {
            controlrect.right = bounds.right
            controlrect.left = controlrect.right - 20
        }
        else {
            controlrect.left = bounds.left
            controlrect.right = controlrect.left + 20
        }
        controlrect.top = bounds.top
        controlrect.bottom = controlrect.top + 20

        ControlRef control
        if(text) {
            osstat = CreatePushButtonControl(nil, &controlrect, text, &control)
            assert(osstat == noErr)

            Int baseLineOffset
            oserr = GetBestControlRect(control, &controlrect, &baseLineOffset)
            assert(oserr == noErr)
            if(right) {
                controlrect.left -= (controlrect.right - bounds.right)
                controlrect.right = bounds.right
            }
            SetControlBounds(control, &controlrect)
        }
        else {
            var icon: IconRef
            oserr = GetIconRef(kOnSystemDisk, kSystemIconsCreator, kHelpIcon, &icon)
            assert(oserr == noErr)

            ControlButtonContentInfo content
            content.contentType = kControlContentIconRef
            content.u.iconRef = icon
            osstat = CreateRoundButtonControl(nil, &controlrect, kControlRoundButtonNormalSize,
                                            &content, &control)
            assert(osstat == noErr)
        }

        oserr = EmbedControl(control, parent)
        assert(oserr == noErr)

        osstat = SetControlCommandID(control, command)
        assert(osstat == noErr)

        switch(command) {
            case kHICommandOK:
                osstat = SetWindowDefaultButton(GetControlOwner(control), control)
                assert(osstat == noErr)
                break
            case kHICommandCancel:
                osstat = SetWindowCancelButton(GetControlOwner(control), control)
                assert(osstat == noErr)
                break
        }

        if(helptext) {
            HMHelpContentRec help
            help.version = kMacHelpVersion
            help.absHotRect.top    = 0
            help.absHotRect.left   = 0
            help.absHotRect.bottom = 0
            help.absHotRect.right  = 0
            help.tagSide = kHMDefaultSide
            help.content[kHMMinimumContentIndex].contentType = kHMCFStringContent
            help.content[kHMMinimumContentIndex].u.tagCFString = helptext
            help.content[kHMMaximumContentIndex].contentType = kHMNoContent
            help.content[kHMMaximumContentIndex].u.tagCFString = nil

            osstat = HMSetControlHelpContent(control, &help)
            assert(osstat == noErr)
        }

        SetControlReference(control, refcon)

        if(right)
            bounds.right = controlrect.left - 12
        else
            bounds.left = controlrect.right + 12

        bounds.bottom = controlrect.bottom

        return control
    }



    public func MakeEditTextControl(parent: ControlRef, bounds: Rect, title: String,
                                    text: String, ispassword: Boolean, helptext: String,
                                    refcon: Int) -> ControlRef {

        var osstat: OSStatus
        var oserr: OSErr

        Rect controlrect

        controlrect.top = bounds.top + 3
        controlrect.left = bounds.left
        controlrect.right = bounds.left + (bounds.right - bounds.left) / 3 - 8

        MakeStaticTextControl(parent, &controlrect, title, teFlushRight, false)

        controlrect.top = controlrect.bottom - 16
        controlrect.left = bounds.left + (bounds.right - bounds.left) / 3 + 3
        controlrect.right = bounds.right - 3

        ControlFontStyleRec style
        style.flags = kControlUseFontMask
        style.font = kControlFontBigSystemFont

        ControlRef control
        osstat = CreateEditUnicodeTextControl(nil, &controlrect, text, ispassword, &style, &control)
        assert(osstat == noErr)

        String singleline = true
        oserr = SetControlData(control, kControlEntireControl, kControlEditTextSingleLineTag,
                                sizeof(String), &singleline)
        assert(oserr == noErr)

        oserr = EmbedControl(control, parent)
        assert(oserr == noErr)

        if(helptext) {
            HMHelpContentRec help
            help.version = kMacHelpVersion
            help.absHotRect.top = 0
            help.absHotRect.left = 0
            help.absHotRect.bottom = 0
            help.absHotRect.right = 0
            help.tagSide = kHMDefaultSide
            help.content[kHMMinimumContentIndex].contentType = kHMCFStringContent
            help.content[kHMMinimumContentIndex].u.tagCFString = helptext
            help.content[kHMMaximumContentIndex].contentType = kHMNoContent
            help.content[kHMMaximumContentIndex].u.tagCFString = nil

            osstat = HMSetControlHelpContent(control, &help)
            assert(osstat == noErr)
        }

        SetControlReference(control, refcon)

        bounds.bottom = controlrect.bottom + 3

        return control
    }



    public func MakeCheckBoxControl(parent: ControlRef, bounds: Rect, text: String,
                                    initval: Int, helptext: String, refcon: Int) -> ControlRef {

        var osstat: OSStatus
        var oserr: OSErr

        Rect controlrect

        controlrect.top = bounds.top
        controlrect.bottom = bounds.top + 18

        controlrect.left = bounds.left + (bounds.right - bounds.left) / 3
        controlrect.right = bounds.right

        ControlRef control
        osstat = CreateCheckBoxControl(nil, &controlrect, text, initval, true, &control)
        assert(osstat == noErr)

        Int baseLineOffset
        oserr = GetBestControlRect(control, &controlrect, &baseLineOffset)
        assert(oserr == noErr)
        if(controlrect.right > bounds.right) {
            controlrect.right = bounds.right
            controlrect.bottom += 14
        }
        SetControlBounds(control, &controlrect)

        oserr = EmbedControl(control, parent)
        assert(oserr == noErr)

        if(helptext) {
            HMHelpContentRec help
            help.version = kMacHelpVersion
            help.absHotRect.top = 0
            help.absHotRect.left = 0
            help.absHotRect.bottom = 0
            help.absHotRect.right = 0
            help.tagSide = kHMDefaultSide
            help.content[kHMMinimumContentIndex].contentType = kHMCFStringContent
            help.content[kHMMinimumContentIndex].u.tagCFString = helptext
            help.content[kHMMaximumContentIndex].contentType = kHMNoContent
            help.content[kHMMaximumContentIndex].u.tagCFString = nil

            osstat = HMSetControlHelpContent(control, &help)
            assert(osstat == noErr)
        }

        SetControlReference(control, refcon)

        bounds.bottom = controlrect.bottom

        return control
    }



    public func MakePopupMenuControl(parent: ControlRef, bounds: Rect, title: String,
                                    menu: MenuRef, selectedItem: MenuItemIndex, helptext: String,
                                    refcon: Int) -> ControlRef {

        var osstat: OSStatus
        var oserr: OSErr

        Rect controlrect

        controlrect.top = bounds.top + 2

        controlrect.left = bounds.left
        controlrect.right = bounds.left + (bounds.right - bounds.left) / 3 - 8

        MakeStaticTextControl(parent, &controlrect, title, teFlushRight, false)

        controlrect.top = controlrect.bottom - 18
        controlrect.bottom = controlrect.top + 20

        controlrect.left = bounds.left + (bounds.right - bounds.left) / 3
        controlrect.right = bounds.right

        ControlRef control
        osstat = CreatePopupButtonControl(nil, &controlrect, nil, -12345, false, -1,
                                        teFlushLeft, normal, &control)
        assert(osstat == noErr)

        osstat = SetControlData(control, kControlMenuPart, kControlPopupButtonOwnedMenuRefTag,
                                sizeof(MenuRef), &menu)
        assert(osstat == noErr)

        SetControlMaximum(control, CountMenuItems(menu))
        SetControlValue(control, selectedItem)

        Int baseLineOffset
        oserr = GetBestControlRect(control, &controlrect, &baseLineOffset)
        assert(oserr == noErr)
        if(controlrect.right > bounds.right) controlrect.right = bounds.right
        SetControlBounds(control, &controlrect)

        oserr = EmbedControl(control, parent)
        assert(oserr == noErr)

        if(helptext) {
            HMHelpContentRec help
            help.version = kMacHelpVersion
            help.absHotRect.top = 0
            help.absHotRect.left = 0
            help.absHotRect.bottom = 0
            help.absHotRect.right = 0
            help.tagSide = kHMDefaultSide
            help.content[kHMMinimumContentIndex].contentType = kHMCFStringContent
            help.content[kHMMinimumContentIndex].u.tagCFString = helptext
            help.content[kHMMaximumContentIndex].contentType = kHMNoContent
            help.content[kHMMaximumContentIndex].u.tagCFString = nil

            osstat = HMSetControlHelpContent(control, &help)
            assert(osstat == noErr)
        }

        SetControlReference(control, refcon)

        bounds.bottom = controlrect.bottom

        return control
    }


    static func SliderLiveAction(ControlRef control, Int part) {}


    static func CreateDefaultValueText(ControlRef control, value: Int) -> String{

        return CFStringCreateWithFormat(nil, nil, CFSTR("%i"), (Int)value)
    }


    static func SliderValueChanged(inHandlerCallRef: EventHandlerCallRef, inEvent: EventRef,
                                        void * inUserData) -> OSStatus {

        var osstat: OSStatus
        var oserr: OSErr

        ControlRef slider
        osstat = GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, nil,
                                    sizeof(ControlRef), nil, &slider)
        assert(osstat == noErr)

        ControlRef valuetext = (ControlRef) inUserData

        CreateValueText: CreateValueTextProc = (CreateValueTextProc) GetControlReference(valuetext)

        var text: String = CreateValueText(slider, GetControl32BitValue(slider))
        oserr = SetControlData(valuetext, kControlEntireControl, kControlStaticTextCFStringTag,
                                sizeof(String), &text)
        assert(oserr == noErr)
        CFRelease(text)

        DrawOneControl(valuetext)

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }


    static func SliderArrowsHit(inHandlerCallRef: EventHandlerCallRef, inEvent: EventRef,
                                    void * inUserData) -> OSStatus {

        var osstat: OSStatus

        ControlRef slider = (ControlRef) inUserData

        ControlPartCode part
        osstat = GetEventParameter(inEvent, kEventParamControlPart, typeControlPartCode, nil,
                                    sizeof(ControlPartCode), nil, &part)
        assert(osstat == noErr)

        value: Int = GetControl32BitValue(slider)
        switch(part) {
            case kControlUpButtonPart:
                if(value < GetControl32BitMaximum(slider)) value++
                break
            case kControlDownButtonPart:
                if(value > GetControl32BitMinimum(slider)) value--
                break
        }
        SetControl32BitValue(slider, value)

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }




    public func MakeSliderControl(parent: ControlRef, bounds: Rect, title: String,
                                minimum: Int, maximum: Int, value: Int,
                                CreateValueText: CreateValueTextProc, helptext: String, refcon: Int) -> ControlRef {

        if(!CreateValueText) CreateValueText = CreateDefaultValueText

        var osstat: OSStatus
        var oserr: OSErr

        Rect controlrect

        controlrect.top = bounds.top

        controlrect.left = bounds.left
        controlrect.right = bounds.left + (bounds.right - bounds.left) / 3 - 8

        MakeStaticTextControl(parent, &controlrect, title, teFlushRight, false)

        controlrect.top = controlrect.bottom - 16
        controlrect.bottom = controlrect.top + 25

        controlrect.left = bounds.left + (bounds.right - bounds.left) / 3
        controlrect.right = bounds.right

        ControlRef slider
        static ControlActionUPP SliderLiveActionUPP = nil
        if(!SliderLiveActionUPP) SliderLiveActionUPP = NewControlActionUPP(SliderLiveAction)
        osstat = CreateSliderControl(nil, &controlrect, value, minimum, maximum,
                                    kControlSliderPointsDownOrRight, 2, true, SliderLiveActionUPP,
                                    &slider)
        assert(osstat == noErr)

        oserr = EmbedControl(slider, parent)
        assert(oserr == noErr)

        if(helptext) {
            HMHelpContentRec help
            help.version = kMacHelpVersion
            help.absHotRect.top = 0
            help.absHotRect.left = 0
            help.absHotRect.bottom = 0
            help.absHotRect.right = 0
            help.tagSide = kHMDefaultSide
            help.content[kHMMinimumContentIndex].contentType = kHMCFStringContent
            help.content[kHMMinimumContentIndex].u.tagCFString = helptext
            help.content[kHMMaximumContentIndex].contentType = kHMNoContent
            help.content[kHMMaximumContentIndex].u.tagCFString = nil

            osstat = HMSetControlHelpContent(slider, &help)
            assert(osstat == noErr)
        }

        SetControlReference(slider, refcon)

        controlrect.top = controlrect.bottom - 3
        controlrect.bottom = controlrect.top + 22

        controlrect.left = bounds.left + 2 * (bounds.right - bounds.left) / 3 + 8
        controlrect.right = controlrect.left + 13

        ControlRef arrows
        osstat = CreateLittleArrowsControl(nil, &controlrect, 0, 0, 1, 0, &arrows)
        assert(osstat == noErr)

        oserr = EmbedControl(arrows, parent)
        assert(oserr == noErr)

        var text: String
        ControlFontStyleRec style
        Rect bestrect
        Int baseLineOffset

        controlrect.top = controlrect.top + 3
        controlrect.bottom = controlrect.top + 16

        controlrect.left = bounds.left + (bounds.right - bounds.left) / 3
        controlrect.right = bounds.left + 2 * (bounds.right - bounds.left) / 3

        style.flags = kControlUseFontMask | kControlUseJustMask
        style.font = kControlFontBigSystemFont
        style.just = teFlushRight

        ControlRef valuetext
        text = CreateValueText(slider, value)
        osstat = CreateStaticTextControl(nil, &controlrect, text, &style, &valuetext)
        assert(osstat == noErr)
        CFRelease(text)

        oserr = EmbedControl(valuetext, parent)
        assert(oserr == noErr)

        controlrect.top = controlrect.bottom - 13

        controlrect.left = bounds.left + (bounds.right - bounds.left) / 3
        controlrect.right = bounds.left + (bounds.right - bounds.left) / 3 + 15

        style.flags = kControlUseFontMask | kControlUseJustMask
        style.font = kControlFontSmallSystemFont
        style.just = teCenter

        ControlRef minimumtext
        text = CreateValueText(slider, minimum)
        osstat = CreateStaticTextControl(nil, &controlrect, text, &style, &minimumtext)
        assert(osstat == noErr)
        CFRelease(text)

        oserr = GetBestControlRect(minimumtext, &bestrect, &baseLineOffset)
        assert(oserr == noErr)

        if(!EqualRect(&controlrect, &bestrect)) {
            controlrect.right = bounds.left + 2 * (bounds.right - bounds.left) / 3 - 25
            SetControlBounds(minimumtext, &controlrect)

            style.flags = kControlUseFontMask | kControlUseJustMask
            style.font = kControlFontSmallSystemFont
            style.just = teFlushLeft
            oserr = SetControlFontStyle(minimumtext, &style)
            assert(oserr == noErr)
        }

        oserr = EmbedControl(minimumtext, parent)
        assert(oserr == noErr)

        controlrect.left = bounds.right - 15
        controlrect.right = bounds.right

        style.flags = kControlUseFontMask | kControlUseJustMask
        style.font = kControlFontSmallSystemFont
        style.just = teCenter

        ControlRef maximumtext
        text = CreateValueText(slider, maximum)
        osstat = CreateStaticTextControl(nil, &controlrect, text, &style, &maximumtext)
        assert(osstat == noErr)
        CFRelease(text)

        oserr = GetBestControlRect(maximumtext, &bestrect, &baseLineOffset)
        assert(oserr == noErr)

        if(!EqualRect(&controlrect, &bestrect)) {
            controlrect.left = bounds.left + 2 * (bounds.right - bounds.left) / 3 + 25
            SetControlBounds(maximumtext, &controlrect)

            style.flags = kControlUseFontMask | kControlUseJustMask
            style.font = kControlFontSmallSystemFont
            style.just = teFlushRight
            oserr = SetControlFontStyle(maximumtext, &style)
            assert(oserr == noErr)
        }

        oserr = EmbedControl(maximumtext, parent)
        assert(oserr == noErr)

        SetControlReference(valuetext, (Int) CreateValueText)

        static EventHandlerUPP SliderValueChangedUPP = nil
        if(!SliderValueChangedUPP) SliderValueChangedUPP = NewEventHandlerUPP(SliderValueChanged)
        osstat = InstallControlEventHandler(slider, SliderValueChangedUPP,
                                            GetEventTypeCount(valueFieldChangedEvent),
                                            valueFieldChangedEvent, valuetext, nil)
        assert(osstat == noErr)

        static EventHandlerUPP SliderArrowsHitUPP = nil
        if(!SliderArrowsHitUPP) SliderArrowsHitUPP = NewEventHandlerUPP(SliderArrowsHit)
        osstat = InstallControlEventHandler(arrows, SliderArrowsHitUPP,
                                            GetEventTypeCount(controlHitEvent),
                                            controlHitEvent, slider, nil)
        assert(osstat == noErr)

        bounds.bottom = controlrect.bottom

        return slider
    }
}