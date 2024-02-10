module Component.DaisyUi exposing (AlertModifier(..), BtnModifier(..), DropdownModifier(..), ExtendedStyle, InputModifier(..), MenuItemModifier(..), MenuModifier(..), SwapModifier(..), ToastModifier(..), alert, alertStyle, attribute, attributes, btn, btnStyle, class, classes, countdown, countdownStyle, dropdown, dropdownContent, dropdownStyle, menu, menuItem, menuItemStyle, menuStyle, menuTitle, menuTitleStyle, mergeStyles, modifier, modifiers, navbar, navbarCenter, navbarCenterStyle, navbarEnd, navbarEndStyle, navbarStart, navbarStartStyle, navbarStyle, stack, stackStyle, style, styles, swap, swapStyle, toast, toastStyle)

import Css exposing (Style, before, important)
import Html.Styled as Dom
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onCheck)
import Tailwind.Classes as Cls



-- GENERAL


merge :
    (modifier -> ( List Style, List String ))
    -> List Style
    -> List String
    -> List modifier
    -> List (Dom.Attribute msg)
    -> List (Dom.Attribute msg)
merge modifierFunc daisyStyles daisyClasses modifierList attributeList =
    let
        classList : Dom.Attribute msg
        classList =
            daisyClasses
                :: modifierClasses
                |> List.concat
                |> List.map (\x -> ( x, True ))
                |> Attr.classList

        ( modifierAttributes, modifierClasses ) =
            List.map modifierFunc modifierList
                |> List.unzip

        styleAttribute : Dom.Attribute msg
        styleAttribute =
            daisyStyles
                :: modifierAttributes
                |> List.concat
                |> Attr.css
    in
    styleAttribute
        :: classList
        :: attributeList


mergeModifiedStyles :
    (modifier -> ( List Style, List String ))
    -> List ( List Style, List String )
    -> List modifier
    -> ( List Style, List String )
mergeModifiedStyles modifierFunc classList modifierList =
    classList
        ++ List.map modifierFunc modifierList
        |> unzip


mergeElement :
    (List modifier -> ( List Style, List String ))
    -> (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg modifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
mergeElement modifierMapFunc element stylings children =
    let
        activeClasses : List ( String, Bool )
        activeClasses =
            classNames
                |> List.map (\name -> ( name, True ))

        attributeList : List (Dom.Attribute msg)
        attributeList =
            List.concatMap .attributes stylings

        classList : List ( List Style, List String )
        classList =
            List.concatMap .classes stylings

        ( styleList, classNames ) =
            classList ++ [ modifierMapFunc modifierList ] |> unzip

        modifierList : List modifier
        modifierList =
            List.concatMap .modifiers stylings
    in
    element
        (Attr.css styleList :: Attr.classList activeClasses :: attributeList)
        children


mergeUnmodifiedElement :
    ( List Style, List String )
    -> (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg modifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
mergeUnmodifiedElement styleTuple element styling =
    mergeElement (\_ -> ( [], [] )) element (class styleTuple :: styling)


mergeUnmodified :
    List Style
    -> List String
    -> List (Dom.Attribute msg)
    -> List (Dom.Attribute msg)
mergeUnmodified daisyStyles daisyClasses =
    merge (\_ -> ( [], [] )) daisyStyles daisyClasses []


mergeUnmodifiedTuple :
    ( List Style, List String )
    -> List (Dom.Attribute msg)
    -> List (Dom.Attribute msg)
mergeUnmodifiedTuple ( daisyStyles, daisyClasses ) =
    mergeUnmodified daisyStyles daisyClasses


mergeStyles :
    List ( List Style, List String )
    -> List (Dom.Attribute msg)
    -> List (Dom.Attribute msg)
mergeStyles classList =
    mergeUnmodifiedTuple (classList |> unzip)


unzip : List ( List a, List b ) -> ( List a, List b )
unzip list =
    let
        ( cssStyles, classList ) =
            List.unzip list
    in
    ( List.concat cssStyles, List.concat classList )



-- EXTENDED-STYLE


type alias ExtendedStyle msg modifier =
    { classes : List ( List Style, List String )
    , attributes : List (Dom.Attribute msg)
    , modifiers : List modifier
    }


class : ( List Style, List String ) -> ExtendedStyle msg modifier
class ( cssStyles, classNames ) =
    { classes = [ ( cssStyles, classNames ) ]
    , attributes = []
    , modifiers = []
    }


classes : List ( List Style, List String ) -> ExtendedStyle msg modifier
classes classList =
    { classes = classList
    , attributes = []
    , modifiers = []
    }


style : Style -> ExtendedStyle msg modifier
style cssStyle =
    { classes = [ ( [ cssStyle ], [] ) ]
    , attributes = []
    , modifiers = []
    }


styles : List Style -> ExtendedStyle msg modifier
styles cssStyles =
    { classes = [ ( cssStyles, [] ) ]
    , attributes = []
    , modifiers = []
    }


attribute : Dom.Attribute msg -> ExtendedStyle msg modifier
attribute attr =
    { classes = []
    , attributes = [ attr ]
    , modifiers = []
    }


attributes : List (Dom.Attribute msg) -> ExtendedStyle msg modifier
attributes attributeList =
    { classes = []
    , attributes = attributeList
    , modifiers = []
    }


modifier : modifier -> ExtendedStyle msg modifier
modifier mod =
    { classes = []
    , attributes = []
    , modifiers = [ mod ]
    }


modifiers : List modifier -> ExtendedStyle msg modifier
modifiers modList =
    { classes = []
    , attributes = []
    , modifiers = modList
    }



-- BUTTON


type BtnModifier
    = BtnNeutral -- Button with `neutral` color
    | BtnPrimary -- Button with `primary` color
    | BtnSecondary -- Button with `secondary` color
    | BtnAccent -- Button with `accent` color
    | BtnInfo -- Button with `info` color
    | BtnSuccess -- Button with `success` color
    | BtnWarning -- Button with `warning` color
    | BtnError -- Button with `error` color
    | BtnGhost -- Button with ghost style
    | BtnLink -- Button styled as a link
    | BtnOutline -- Transparent Button with colored border
    | BtnActive -- Force button to show active state
    | BtnDisabled -- Force button to show disabled state
    | BtnGlass -- Button with a glass effect
    | BtnNoAnimation -- Disables click animation
    | BtnLg -- Large button
    | BtnMd -- Medium button (default)
    | BtnSm -- Small button
    | BtnXs -- Extra small button
    | BtnWide -- Wide button (more horizontal padding)
    | BtnBlock -- Full width button
    | BtnCircle -- Circle button with a 1:1 ratio
    | BtnSquare -- Square button with a 1:1 ratio


btnModifier : BtnModifier -> ( List Style, List String )
btnModifier mod =
    case mod of
        BtnNeutral ->
            Cls.btn_neutral

        BtnPrimary ->
            Cls.btn_primary

        BtnSecondary ->
            Cls.btn_secondary

        BtnAccent ->
            Cls.btn_accent

        BtnInfo ->
            Cls.btn_info

        BtnSuccess ->
            Cls.btn_success

        BtnWarning ->
            Cls.btn_warning

        BtnError ->
            Cls.btn_error

        BtnGhost ->
            Cls.btn_ghost

        BtnLink ->
            Cls.btn_link

        BtnOutline ->
            Cls.btn_outline

        BtnActive ->
            Cls.btn_active

        BtnDisabled ->
            Cls.btn_disabled

        BtnGlass ->
            Cls.glass

        BtnNoAnimation ->
            Cls.no_animation

        BtnLg ->
            Cls.btn_lg

        BtnMd ->
            Cls.btn_md

        BtnSm ->
            Cls.btn_sm

        BtnXs ->
            Cls.btn_xs

        BtnWide ->
            Cls.btn_wide

        BtnBlock ->
            Cls.btn_block

        BtnCircle ->
            Cls.btn_circle

        BtnSquare ->
            Cls.btn_square


{-| Buttons allow the user to take actions or make choices.
Button.

<https://daisyui.com/components/button/>

-}
btnStyle :
    List BtnModifier
    -> ( List Style, List String )
btnStyle =
    mergeModifiedStyles btnModifier [ Cls.btn ]


{-| Buttons allow the user to take actions or make choices.
Button.

<https://daisyui.com/components/button/>

-}
btn :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg BtnModifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
btn element styling children =
    mergeElement btnStyle element styling children



-- DROPDOWN


type DropdownModifier
    = DropdownEnd -- Aligns to end
    | DropdownTop -- Open from top
    | DropdownBottom -- Open from bottom
    | DropdownLeft -- Open from left
    | DropdownRight -- Open from right
    | DropdownHover -- Opens on hover too
    | DropdownOpen -- Force open


dropdownModifier : DropdownModifier -> ( List Style, List String )
dropdownModifier mod =
    case mod of
        DropdownEnd ->
            Cls.dropdown_end

        DropdownTop ->
            Cls.dropdown_top

        DropdownBottom ->
            Cls.dropdown_bottom

        DropdownLeft ->
            Cls.dropdown_left

        DropdownRight ->
            Cls.dropdown_right

        DropdownHover ->
            Cls.dropdown_hover

        DropdownOpen ->
            Cls.dropdown_open


{-| Dropdown can open a menu or any other element when the button is clicked.
Container element.

<https://daisyui.com/components/dropdown/>

-}
dropdownStyle :
    List DropdownModifier
    -> ( List Style, List String )
dropdownStyle =
    mergeModifiedStyles dropdownModifier [ Cls.dropdown ]


{-| Dropdown can open a menu or any other element when the button is clicked.
Container element.

<https://daisyui.com/components/dropdown/>

-}
dropdown :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg DropdownModifier)
    -> List (Dom.Html msg)
    -> (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
dropdown element styling openerContent contentElement contentStyling content =
    let
        inner : Dom.Html msg
        inner =
            mergeUnmodifiedElement
                dropdownContentStyle
                contentElement
                contentStyling
                content
    in
    mergeElement dropdownStyle
        element
        ((Attr.tabindex -1 |> attribute) :: styling)
        (openerContent ++ [ inner ])


{-| Dropdown container for content.
Use inside of `dropdown` component.

<https://daisyui.com/components/dropdown/>

-}
dropdownContentStyle : ( List Style, List String )
dropdownContentStyle =
    Cls.dropdown_content


{-| Dropdown container for content.
Use inside of `dropdown` component.

<https://daisyui.com/components/dropdown/>

-}
dropdownContent :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
dropdownContent element styling content =
    mergeUnmodifiedElement
        dropdownContentStyle
        element
        styling
        content



-- NAVBAR


{-| Navbar is used to show a navigation bar on the top of the page.
Container element.

<https://daisyui.com/components/navbar/>

-}
navbarStyle : ( List Style, List String )
navbarStyle =
    Cls.navbar


{-| Navbar is used to show a navigation bar on the top of the page.
Container element.

<https://daisyui.com/components/navbar/>

-}
navbar :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
navbar element styling content =
    mergeUnmodifiedElement
        navbarStyle
        element
        styling
        content


{-| Child element, fills 50% of width to be on start.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarStartStyle : ( List Style, List String )
navbarStartStyle =
    Cls.navbar_start


{-| Child element, fills 50% of width to be on start.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarStart :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
navbarStart element styling content =
    mergeUnmodifiedElement navbarStartStyle
        element
        styling
        content


{-| Child element, fills remaining space to be on center.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarCenterStyle : ( List Style, List String )
navbarCenterStyle =
    Cls.navbar_center


{-| Child element, fills remaining space to be on center.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarCenter :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
navbarCenter element styling content =
    mergeUnmodifiedElement navbarCenterStyle
        element
        styling
        content


{-| Child element, fills 50% of width to be on end.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarEndStyle : ( List Style, List String )
navbarEndStyle =
    Cls.navbar_end


{-| Child element, fills 50% of width to be on end.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarEnd :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
navbarEnd element styling content =
    mergeUnmodifiedElement navbarEndStyle
        element
        styling
        content



-- MENU


type MenuModifier
    = MenuXs -- Extra small size
    | MenuSm -- Small size
    | MenuMd -- Medium size (default)
    | MenuLg -- Large size
    | MenuVertical -- Vertical menu (default)
    | MenuHorizontal -- Horizontal menu


type MenuItemModifier
    = MenuDisabled -- Sets <li> as disabled
    | MenuActive -- Applies actives style to the element inside <li>
    | MenuFocus -- Applies focus style to the element inside <li>


menuModifier : MenuModifier -> ( List Style, List String )
menuModifier mod =
    case mod of
        MenuXs ->
            Cls.menu_xs

        MenuSm ->
            Cls.menu_sm

        MenuMd ->
            Cls.menu_md

        MenuLg ->
            Cls.menu_lg

        MenuVertical ->
            Cls.menu_vertical

        MenuHorizontal ->
            Cls.menu_horizontal


menuItemModifier : MenuItemModifier -> ( List Style, List String )
menuItemModifier mod =
    case mod of
        MenuDisabled ->
            Cls.disabled

        MenuActive ->
            Cls.active

        MenuFocus ->
            Cls.focus


{-| Menu is used to display a list of links vertically or horizontally. (`<ul>`)
Container <ul> element.

<https://daisyui.com/components/menu/>

-}
menuStyle :
    List MenuModifier
    -> ( List Style, List String )
menuStyle =
    mergeModifiedStyles menuModifier [ Cls.menu ]


{-| Menu is used to display a list of links vertically or horizontally. (`<ul>`)
Container <ul> element.

<https://daisyui.com/components/menu/>

-}
menu :
    List (ExtendedStyle msg MenuModifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
menu styling content =
    mergeElement menuStyle Dom.ul styling content


{-| Specifies the title of menu.
Use inside of `menu` component.

<https://daisyui.com/components/menu/>

-}
menuTitleStyle : ( List Style, List String )
menuTitleStyle =
    Cls.menu_title


{-| Specifies the title of menu.
Use inside of `menu` component.

<https://daisyui.com/components/menu/>

-}
menuTitle :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
menuTitle element styling content =
    mergeUnmodifiedElement menuTitleStyle
        element
        styling
        content


{-| Item of menu. (`<li>`)
Use inside of `menu` component.

<https://daisyui.com/components/menu/>

-}
menuItemStyle :
    List MenuItemModifier
    -> ( List Style, List String )
menuItemStyle =
    mergeModifiedStyles menuItemModifier []


{-| Item of menu. (`<li>`)
Use inside of `menu` component.

<https://daisyui.com/components/menu/>

-}
menuItem :
    List (ExtendedStyle msg MenuItemModifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
menuItem styling content =
    mergeElement menuItemStyle Dom.li styling content



-- STACK


{-| Stack visually puts elements on top of each other.

<https://daisyui.com/components/stack/>

-}
stackStyle : ( List Style, List String )
stackStyle =
    Cls.stack


{-| Stack visually puts elements on top of each other.

<https://daisyui.com/components/stack/>

-}
stack :
    (List (Dom.Attribute msg) -> List (Dom.Html msg) -> Dom.Html msg)
    -> List (ExtendedStyle msg ())
    -> List (Dom.Html msg)
    -> Dom.Html msg
stack element styling content =
    mergeUnmodifiedElement stackStyle
        element
        styling
        content



-- TOAST


type ToastModifier
    = ToastStart -- Align horizontally to the left
    | ToastCenter -- Align horizontally to the center
    | ToastEnd -- Align horizontally to the right (default)
    | ToastTop -- Align vertically to top
    | ToastMiddle -- Align vertically to middle
    | ToastBottom -- Align vertically to bottom (default)


toastModifier : ToastModifier -> ( List Style, List String )
toastModifier mod =
    case mod of
        ToastStart ->
            ( [], [ "toast-start" ] )

        ToastCenter ->
            Cls.toast_center

        ToastEnd ->
            ( [], [ "toast-end" ] )

        ToastTop ->
            ( [], [ "toast-top" ] )

        ToastMiddle ->
            ( [], [ "toast-middle" ] )

        ToastBottom ->
            ( [], [ "toast-bottom" ] )


{-| Toast is a wrapper to stack elements, positioned on the corner of page.

<https://daisyui.com/components/toast/>

-}
toastStyle :
    List ToastModifier
    -> ( List Style, List String )
toastStyle =
    mergeModifiedStyles toastModifier [ Cls.toast ]


{-| Toast is a wrapper to stack elements, positioned on the corner of page.

<https://daisyui.com/components/toast/>

-}
toast :
    List (ExtendedStyle msg ToastModifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
toast styling content =
    mergeElement toastStyle Dom.div styling content



-- ALERT


type AlertModifier
    = AlertInfo -- Alert with `info` color
    | AlertSuccess -- Alert with `success` color
    | AlertWarning -- Alert with `warning` color
    | AlertError -- Alert with `error` color


alertModifier : AlertModifier -> ( List Style, List String )
alertModifier mod =
    case mod of
        AlertInfo ->
            unzip [ Cls.alert_info ]

        AlertSuccess ->
            Cls.alert_success

        AlertWarning ->
            Cls.alert_warning

        AlertError ->
            Cls.alert_error


{-| Alert informs users about important events.

<https://daisyui.com/components/alert/>

-}
alertStyle :
    List AlertModifier
    -> ( List Style, List String )
alertStyle =
    mergeModifiedStyles alertModifier [ Cls.alert ]


{-| Alert informs users about important events.

<https://daisyui.com/components/alert/>

-}
alert :
    List (ExtendedStyle msg AlertModifier)
    -> List (Dom.Html msg)
    -> Dom.Html msg
alert styling content =
    mergeElement
        alertStyle
        Dom.div
        (attribute
            (Attr.attribute "role" "alert")
            :: styling
        )
        content



-- INPUT


type InputModifier
    = InputBordered -- Adds border to input
    | InputGhost -- Adds ghost style to input
    | InputPrimary -- Adds `primary` color to input
    | InputSecondary -- Adds `secondary` color to input
    | InputAccent -- Adds `accent` color to input
    | InputInfo -- Adds `info` color to input
    | InputSuccess -- Adds `success` color to input
    | InputWarning -- Adds `warning` color to input
    | InputError -- Adds `error` color to input
    | InputLg -- Large size for input
    | InputMd -- Medium (default) size for input
    | InputSm -- Small size for input
    | InputXs -- Extra small size for input



-- COUNTDOWN


{-| Countdown gives you a transition effect of changing numbers.
Value must be a number between 0 and 99.

<https://daisyui.com/components/countdown/>

-}
countdownStyle : ( List Style, List String )
countdownStyle =
    Cls.countdown


{-| Countdown gives you a transition effect of changing numbers.
Value must be a number between 0 and 99.

<https://daisyui.com/components/countdown/>

-}
countdown :
    List (ExtendedStyle msg ())
    -> List Style
    -> Int
    -> Dom.Html msg
countdown styling valueStyle value =
    let
        lastTwoDigits : Int
        lastTwoDigits =
            abs value
                |> modBy 100
    in
    mergeUnmodifiedElement countdownStyle
        Dom.span
        styling
        [ Dom.span
            [ Attr.attribute "style"
                ([ "--value:"
                 , String.fromInt lastTwoDigits
                 , ";"
                 ]
                    |> String.concat
                )
            , Attr.css
                [ before
                    (List.map important valueStyle)
                ]
            ]
            []
        ]



-- SWAP


type SwapModifier
    = SwapActive -- Activates the swap (no need for checkbox)
    | SwapRotate -- Adds rotate effect to swap
    | SwapFlip -- Adds flip effect to swap


swapModifier : SwapModifier -> ( List Style, List String )
swapModifier mod =
    case mod of
        SwapActive ->
            Cls.swap_active

        SwapRotate ->
            Cls.swap_rotate

        SwapFlip ->
            Cls.swap_flip


{-| Swap allows you to toggle the visibility of two elements using a checkbox or a class name.

<https://daisyui.com/components/swap/>

-}
swapStyle :
    List SwapModifier
    -> ( List Style, List String )
swapStyle =
    mergeModifiedStyles swapModifier [ Cls.swap ]


{-| Swap allows you to toggle the visibility of two elements using a checkbox or a class name.

<https://daisyui.com/components/swap/>

-}
swap :
    List (ExtendedStyle msg SwapModifier)
    -> List (Dom.Html msg)
    -> List (Dom.Html msg)
    -> List (Dom.Html msg)
    -> Maybe (Bool -> msg)
    -> Bool
    -> Dom.Html msg
swap styling onContent offContent indeterminateContent onChange isOn =
    mergeElement swapStyle
        Dom.label
        styling
        (Dom.input
            (Attr.type_ "checkbox"
                :: Attr.checked isOn
                :: (case onChange of
                        Just msg ->
                            [ onCheck msg ]

                        Nothing ->
                            []
                   )
            )
            []
            :: List.concat
                [ case onContent of
                    [] ->
                        []

                    content ->
                        [ mergeUnmodifiedElement Cls.swap_on Dom.div [] content ]
                , case offContent of
                    [] ->
                        []

                    content ->
                        [ mergeUnmodifiedElement Cls.swap_off Dom.div [] content ]
                , case indeterminateContent of
                    [] ->
                        []

                    content ->
                        [ mergeUnmodifiedElement Cls.swap_indeterminate Dom.div [] content
                        ]
                ]
        )
