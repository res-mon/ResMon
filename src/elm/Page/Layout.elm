module Page.Layout exposing (Model, Msg, init, update, view)

import Browser exposing (Document)
import Component.DaisyUi as D exposing (SwapModifier(..), modifier)
import Component.Icon as Icon
import Css.Global exposing (global)
import Html.Styled exposing (Html, a, button, div, fromUnstyled, h3, img, li, main_, span, text, toUnstyled, ul)
import Html.Styled.Attributes exposing (attribute, css, href, src, tabindex)
import Html.Styled.Events exposing (onClick)
import List exposing (map)
import Model.Shared exposing (AlertLevel(..), SharedModel, removeAlert, setDarkModeMessage)
import Tailwind.Classes exposing (shadow_lg)
import Tailwind.Theme exposing (base_100, base_300)
import Tailwind.Utilities
    exposing
        ( bg_color
        , duration_500
        , flex_1
        , flex_none
        , float_right
        , font_bold
        , font_mono
        , globalStyles
        , grid
        , h_full
        , h_screen
        , justify_between
        , m_4
        , mt_3
        , p_16
        , p_2
        , place_items_center
        , rounded_box
        , shadow_md
        , text_2xl
        , text_3xl
        , text_4xl
        , text_7xl
        , text_xl
        , w_52
        , z_10
        )
import Time



-- MODEL


type alias Model msg =
    { toMsg : Msg msg -> msg
    }


init : (Msg msg -> msg) -> SharedModel msg -> ( Model msg, Cmd msg )
init toMsg _ =
    ( { toMsg = toMsg }, Cmd.none )



-- UPDATE


type Msg msg
    = RemoveAlert Int


update : Msg msg -> SharedModel msg -> Model msg -> ( SharedModel msg, Model msg, Cmd msg )
update msg shared model =
    case msg of
        RemoveAlert number ->
            ( removeAlert shared number, model, Cmd.none )



-- VIEW


view : SharedModel msg -> Model msg -> Bool -> Document msg -> Document msg
view shared model minimal body =
    let
        content : List (Html msg)
        content =
            List.concat
                [ if minimal then
                    []

                  else
                    [ navigation shared model
                    ]
                , [ mainElement
                  ]
                , if minimal then
                    []

                  else
                    [ footer shared model ]
                ]

        mainElement : Html msg
        mainElement =
            main_
                [ css
                    [ p_16
                    , bg_color base_100
                    , grid
                    , h_screen
                    , place_items_center
                    ]
                ]
                (div [ css [ text_7xl, font_mono ] ]
                    [ D.countdown []
                        [ duration_500 ]
                        (Maybe.map2 Time.toHour shared.timeZone shared.time |> Maybe.withDefault 0)
                    , text ":"
                    , D.countdown []
                        [ duration_500 ]
                        (Maybe.map2 Time.toMinute shared.timeZone shared.time |> Maybe.withDefault 0)
                    , text ":"
                    , D.countdown []
                        [ duration_500 ]
                        (Maybe.map2 Time.toSecond shared.timeZone shared.time |> Maybe.withDefault 0)
                    ]
                    :: map fromUnstyled body.body
                )
    in
    { title = body.title ++ " - ResMon"
    , body =
        [ global globalStyles
        , div
            [ attribute "data-theme"
                (if shared.darkMode then
                    "dark"

                 else
                    "light"
                )
            ]
            (alerts model.toMsg shared.alerts
                :: content
            )
        ]
            |> map toUnstyled
    }


navigation : SharedModel msg -> Model msg -> Html msg
navigation shared _ =
    D.navbar div
        [ bg_color base_300 |> D.style ]
        [ div [ css [ flex_none ] ]
            [ D.btn button
                [ D.modifiers [ D.BtnPrimary, D.BtnSquare, D.BtnGhost ] ]
                [ Icon.list [ text_4xl ]
                ]
            ]
        , div [ css [ flex_1 ] ]
            [ D.btn a
                [ D.modifiers [ D.BtnLink ]
                , href "/" |> D.attribute
                ]
                [ img
                    [ src <|
                        if shared.darkMode then
                            "/img/logo/svg/full-text-inverted.svg"

                        else
                            "/img/logo/svg/full-text.svg"
                    , css [ h_full ]
                    ]
                    []
                ]
            ]
        , D.dropdown div
            [ D.modifier D.DropdownEnd ]
            [ D.btn div
                [ D.modifier D.BtnGhost
                , [ attribute "role" "button"
                  , tabindex 0
                  ]
                    |> D.attributes
                ]
                [ Icon.threeDots [ text_4xl ] ]
            ]
            ul
            [ D.styles
                [ mt_3
                , p_2
                , shadow_md
                , bg_color base_300
                , rounded_box
                , w_52
                , z_10
                ]
            , D.classes
                [ D.menuStyle [ D.MenuSm ]
                ]
            ]
            [ li []
                [ span
                    [ css [ justify_between, text_2xl ]
                    , onClick (setDarkModeMessage shared (not shared.darkMode))
                    ]
                    [ text <|
                        if shared.darkMode then
                            "Light-Mode"

                        else
                            "Dark-Mode"
                    , D.swap
                        [ modifier SwapRotate
                        , D.styles [ float_right, m_4 ]
                        ]
                        [ Icon.sunFill [] ]
                        [ Icon.moonFill [] ]
                        []
                        Nothing
                        shared.darkMode
                    ]
                ]
            ]
        ]


footer : SharedModel msg -> Model msg -> Html msg
footer _ _ =
    div []
        []


alerts : (Msg msg -> msg) -> List (Model.Shared.Alert msg) -> Html msg
alerts toMsg items =
    D.toast
        [ D.modifiers [ D.ToastTop, D.ToastEnd ] ]
        (map (alert toMsg) items)


alert : (Msg msg -> msg) -> Model.Shared.Alert msg -> Html msg
alert toMsg item =
    let
        ( ico, alertModifier, btnModifier ) =
            case item.level of
                AlertNone ->
                    ( Icon.infoCircle
                    , []
                    , [ D.BtnPrimary ]
                    )

                AlertInfo ->
                    ( Icon.infoCircle
                    , [ D.AlertInfo ]
                    , [ D.BtnInfo ]
                    )

                AlertSuccess ->
                    ( Icon.checkCircle
                    , [ D.AlertSuccess ]
                    , [ D.BtnSuccess ]
                    )

                AlertWarning ->
                    ( Icon.exclamationTriangle
                    , [ D.AlertWarning ]
                    , [ D.BtnWarning ]
                    )

                AlertError ->
                    ( Icon.xCircle
                    , [ D.AlertError ]
                    , [ D.BtnError ]
                    )
    in
    D.alert [ D.modifiers alertModifier, D.class shadow_lg ]
        [ ico [ text_3xl ]
        , div []
            [ h3 [ css [ font_bold, text_xl ] ] item.title
            , div [] item.message
            ]
        , D.btn button
            [ D.modifiers btnModifier
            , D.attribute <| onClick (RemoveAlert item.number |> toMsg)
            ]
            [ text "Löschen"
            ]
        ]
