module Component.DaisyUi exposing (AlertModifier(..), BtnModifier(..), DropdownModifier(..), InputModifier(..), MenuItemModifier(..), MenuModifier(..), ToastModifier(..), alert, alertStyle, btn, btnStyle, countdown, countdownStyle, dropdown, dropdownContent, dropdownStyle, menu, menuItem, menuItemStyle, menuStyle, menuTitle, menuTitleStyle, mergeStyles, navbar, navbarCenter, navbarCenterStyle, navbarEnd, navbarEndStyle, navbarStart, navbarStartStyle, navbarStyle, stack, stackStyle, toast, toastStyle)

import Css exposing (Style, before, important)
import Html.Styled exposing (Attribute, Html, div, li, span, ul)
import Html.Styled.Attributes exposing (attribute, classList, css)
import Svg.Styled exposing (style)
import Tailwind.Classes as C



-- GENERAL


merge :
    (modifier -> ( List Style, List String ))
    -> List Style
    -> List String
    -> List modifier
    -> List (Attribute msg)
    -> List (Attribute msg)
merge modifier daisyStyles daisyClasses modifiers attributes =
    let
        ( modifierAttributes, modifierClasses ) =
            List.map modifier modifiers
                |> List.unzip

        class : Attribute msg
        class =
            daisyClasses
                :: modifierClasses
                |> List.concat
                |> List.map (\x -> ( x, True ))
                |> classList

        style : Attribute msg
        style =
            daisyStyles
                :: modifierAttributes
                |> List.concat
                |> css
    in
    style
        :: class
        :: attributes


mergeModifiedStyles :
    (modifier -> ( List Style, List String ))
    -> List ( List Style, List String )
    -> List modifier
    -> ( List Style, List String )
mergeModifiedStyles modifier classes modifiers =
    classes
        ++ List.map modifier modifiers
        |> unzip


mergeElement :
    (List modifier -> ( List Style, List String ))
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List modifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
mergeElement modifiedStyle element classes modifiers attributes children =
    let
        ( styles, classNames ) =
            classes ++ [ modifiedStyle modifiers ] |> unzip

        class : List ( String, Bool )
        class =
            classNames
                |> List.map (\name -> ( name, True ))
    in
    element
        (css styles :: classList class :: attributes)
        children


mergeUnmodifiedElement :
    ( List Style, List String )
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
mergeUnmodifiedElement style element classes =
    mergeElement (\_ -> style) element classes []


mergeUnmodified :
    List Style
    -> List String
    -> List (Attribute msg)
    -> List (Attribute msg)
mergeUnmodified daisyStyles daisyClasses =
    merge (\_ -> ( [], [] )) daisyStyles daisyClasses []


mergeUnmodifiedTuple :
    ( List Style, List String )
    -> List (Attribute msg)
    -> List (Attribute msg)
mergeUnmodifiedTuple ( daisyStyles, daisyClasses ) =
    mergeUnmodified daisyStyles daisyClasses


mergeStyles :
    List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Attribute msg)
mergeStyles classes =
    mergeUnmodifiedTuple (classes |> unzip)


unzip : List ( List a, List b ) -> ( List a, List b )
unzip list =
    let
        ( styles, classes ) =
            List.unzip list
    in
    ( List.concat styles, List.concat classes )



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
btnModifier modifier =
    case modifier of
        BtnNeutral ->
            C.btn_neutral

        BtnPrimary ->
            C.btn_primary

        BtnSecondary ->
            C.btn_secondary

        BtnAccent ->
            C.btn_accent

        BtnInfo ->
            C.btn_info

        BtnSuccess ->
            C.btn_success

        BtnWarning ->
            C.btn_warning

        BtnError ->
            C.btn_error

        BtnGhost ->
            C.btn_ghost

        BtnLink ->
            C.btn_link

        BtnOutline ->
            C.btn_outline

        BtnActive ->
            C.btn_active

        BtnDisabled ->
            C.btn_disabled

        BtnGlass ->
            C.glass

        BtnNoAnimation ->
            C.no_animation

        BtnLg ->
            C.btn_lg

        BtnMd ->
            C.btn_md

        BtnSm ->
            C.btn_sm

        BtnXs ->
            C.btn_xs

        BtnWide ->
            C.btn_wide

        BtnBlock ->
            C.btn_block

        BtnCircle ->
            C.btn_circle

        BtnSquare ->
            C.btn_square


{-| Buttons allow the user to take actions or make choices.
Button.

<https://daisyui.com/components/button/>

-}
btnStyle :
    List BtnModifier
    -> ( List Style, List String )
btnStyle =
    mergeModifiedStyles btnModifier [ C.btn ]


{-| Buttons allow the user to take actions or make choices.
Button.

<https://daisyui.com/components/button/>

-}
btn :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List BtnModifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
btn =
    mergeElement btnStyle



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
dropdownModifier modifier =
    case modifier of
        DropdownEnd ->
            C.dropdown_end

        DropdownTop ->
            C.dropdown_top

        DropdownBottom ->
            C.dropdown_bottom

        DropdownLeft ->
            C.dropdown_left

        DropdownRight ->
            C.dropdown_right

        DropdownHover ->
            C.dropdown_hover

        DropdownOpen ->
            C.dropdown_open


{-| Dropdown can open a menu or any other element when the button is clicked.
Container element.

<https://daisyui.com/components/dropdown/>

-}
dropdownStyle :
    List DropdownModifier
    -> ( List Style, List String )
dropdownStyle =
    mergeModifiedStyles dropdownModifier [ C.dropdown ]


{-| Dropdown can open a menu or any other element when the button is clicked.
Container element.

<https://daisyui.com/components/dropdown/>

-}
dropdown :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List DropdownModifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
dropdown element dropdownClasses modifiers dropdownAttributes dropdownOpener contentElement contentClasses contentAttributes content =
    let
        inner : Html msg
        inner =
            mergeUnmodifiedElement dropdownContentStyle contentElement contentClasses contentAttributes content
    in
    mergeElement dropdownStyle
        element
        dropdownClasses
        modifiers
        dropdownAttributes
        (dropdownOpener ++ [ inner ])


{-| Dropdown container for content.
Use inside of `dropdown` component.

<https://daisyui.com/components/dropdown/>

-}
dropdownContentStyle : ( List Style, List String )
dropdownContentStyle =
    C.dropdown_content


{-| Dropdown container for content.
Use inside of `dropdown` component.

<https://daisyui.com/components/dropdown/>

-}
dropdownContent :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
dropdownContent =
    mergeUnmodifiedElement dropdownContentStyle



-- NAVBAR


{-| Navbar is used to show a navigation bar on the top of the page.
Container element.

<https://daisyui.com/components/navbar/>

-}
navbarStyle : ( List Style, List String )
navbarStyle =
    C.navbar


{-| Navbar is used to show a navigation bar on the top of the page.
Container element.

<https://daisyui.com/components/navbar/>

-}
navbar :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
navbar =
    mergeUnmodifiedElement navbarStyle


{-| Child element, fills 50% of width to be on start.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarStartStyle : ( List Style, List String )
navbarStartStyle =
    C.navbar_start


{-| Child element, fills 50% of width to be on start.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarStart :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
navbarStart =
    mergeUnmodifiedElement navbarStartStyle


{-| Child element, fills remaining space to be on center.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarCenterStyle : ( List Style, List String )
navbarCenterStyle =
    C.navbar_center


{-| Child element, fills remaining space to be on center.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarCenter :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
navbarCenter =
    mergeUnmodifiedElement navbarCenterStyle


{-| Child element, fills 50% of width to be on end.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarEndStyle : ( List Style, List String )
navbarEndStyle =
    C.navbar_end


{-| Child element, fills 50% of width to be on end.
Use inside of `navbar` component.

<https://daisyui.com/components/navbar/>

-}
navbarEnd :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
navbarEnd =
    mergeUnmodifiedElement navbarEndStyle



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
menuModifier modifier =
    case modifier of
        MenuXs ->
            C.menu_xs

        MenuSm ->
            C.menu_sm

        MenuMd ->
            C.menu_md

        MenuLg ->
            C.menu_lg

        MenuVertical ->
            C.menu_vertical

        MenuHorizontal ->
            C.menu_horizontal


menuItemModifier : MenuItemModifier -> ( List Style, List String )
menuItemModifier modifier =
    case modifier of
        MenuDisabled ->
            C.disabled

        MenuActive ->
            C.active

        MenuFocus ->
            C.focus


{-| Menu is used to display a list of links vertically or horizontally. (`<ul>`)
Container <ul> element.

<https://daisyui.com/components/menu/>

-}
menuStyle :
    List MenuModifier
    -> ( List Style, List String )
menuStyle =
    mergeModifiedStyles menuModifier [ C.menu ]


{-| Menu is used to display a list of links vertically or horizontally. (`<ul>`)
Container <ul> element.

<https://daisyui.com/components/menu/>

-}
menu :
    List ( List Style, List String )
    -> List MenuModifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
menu =
    mergeElement menuStyle ul


{-| Specifies the title of menu.
Use inside of `menu` component.

<https://daisyui.com/components/menu/>

-}
menuTitleStyle : ( List Style, List String )
menuTitleStyle =
    C.menu_title


{-| Specifies the title of menu.
Use inside of `menu` component.

<https://daisyui.com/components/menu/>

-}
menuTitle :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
menuTitle =
    mergeUnmodifiedElement menuTitleStyle


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
    List ( List Style, List String )
    -> List MenuItemModifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
menuItem =
    mergeElement menuItemStyle li



-- STACK


{-| Stack visually puts elements on top of each other.

<https://daisyui.com/components/stack/>

-}
stackStyle : ( List Style, List String )
stackStyle =
    C.stack


{-| Stack visually puts elements on top of each other.

<https://daisyui.com/components/stack/>

-}
stack :
    (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List ( List Style, List String )
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
stack =
    mergeUnmodifiedElement stackStyle



-- TOAST


type ToastModifier
    = ToastStart -- Align horizontally to the left
    | ToastCenter -- Align horizontally to the center
    | ToastEnd -- Align horizontally to the right (default)
    | ToastTop -- Align vertically to top
    | ToastMiddle -- Align vertically to middle
    | ToastBottom -- Align vertically to bottom (default)


toastModifier : ToastModifier -> ( List Style, List String )
toastModifier modifier =
    case modifier of
        ToastStart ->
            ( [], [ "toast-start" ] )

        ToastCenter ->
            C.toast_center

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
    mergeModifiedStyles toastModifier [ C.toast ]


{-| Toast is a wrapper to stack elements, positioned on the corner of page.

<https://daisyui.com/components/toast/>

-}
toast :
    List ( List Style, List String )
    -> List ToastModifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
toast =
    mergeElement toastStyle div



-- ALERT


type AlertModifier
    = AlertInfo -- Alert with `info` color
    | AlertSuccess -- Alert with `success` color
    | AlertWarning -- Alert with `warning` color
    | AlertError -- Alert with `error` color


alertModifier : AlertModifier -> ( List Style, List String )
alertModifier modifier =
    case modifier of
        AlertInfo ->
            unzip [ C.alert_info ]

        AlertSuccess ->
            C.alert_success

        AlertWarning ->
            C.alert_warning

        AlertError ->
            C.alert_error


{-| Alert informs users about important events.

<https://daisyui.com/components/alert/>

-}
alertStyle :
    List AlertModifier
    -> ( List Style, List String )
alertStyle =
    mergeModifiedStyles alertModifier [ C.alert ]


{-| Alert informs users about important events.

<https://daisyui.com/components/alert/>

-}
alert :
    List ( List Style, List String )
    -> List AlertModifier
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
alert classes modifiers attributes =
    mergeElement
        alertStyle
        div
        classes
        modifiers
        (attribute "role" "alert" :: attributes)



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
    C.countdown


{-| Countdown gives you a transition effect of changing numbers.
Value must be a number between 0 and 99.

<https://daisyui.com/components/countdown/>

-}
countdown :
    List ( List Style, List String )
    -> List (Attribute msg)
    -> List Style
    -> Int
    -> Html msg
countdown classes attributes valueStyle value =
    let
        lastTwoDigits =
            abs value
                |> modBy 100
    in
    mergeUnmodifiedElement countdownStyle
        span
        classes
        attributes
        [ span
            [ attribute "style"
                ([ "--value:"
                 , String.fromInt lastTwoDigits
                 , ";"
                 ]
                    |> String.concat
                )
            , css
                [ before
                    (List.map important valueStyle)
                ]
            ]
            []
        ]
