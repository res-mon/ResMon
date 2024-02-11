module Page.Layout exposing (Model, Msg, init, update, view)

import Browser exposing (Document)
import Component.DaisyUi as Ui
import Component.Icon as Ico
import Css.Global exposing (global)
import Html.Styled as Dom
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import List exposing (map)
import Model.Shared
    exposing
        ( AlertLevel(..)
        , SharedModel
        , removeAlert
        , setDarkModeMessage
        )
import Tailwind.Breakpoints as Br
import Tailwind.Classes as Cls
import Tailwind.Theme as Color
import Tailwind.Utilities as Tw
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


update :
    Msg msg
    -> SharedModel msg
    -> Model msg
    -> ( SharedModel msg, Model msg, Cmd msg )
update msg shared model =
    case msg of
        RemoveAlert number ->
            ( removeAlert shared number, model, Cmd.none )



-- VIEW


view : SharedModel msg -> Model msg -> Bool -> Document msg -> Document msg
view shared model minimal body =
    let
        content : List (Dom.Html msg)
        content =
            List.concat
                [ if minimal then
                    []

                  else
                    [ Dom.header []
                        [ navigation shared model
                        ]
                    ]
                , [ mainElement
                  ]
                , if minimal then
                    []

                  else
                    [ footer shared model ]
                ]

        mainElement : Dom.Html msg
        mainElement =
            Dom.main_
                [ Attr.css
                    [ Tw.p_16
                    , Tw.bg_color Color.base_100
                    , Tw.grid
                    , Tw.flex_1
                    , Tw.place_items_center
                    ]
                ]
                (Dom.div
                    [ Attr.css
                        [ Tw.text_5xl
                        , Tw.font_mono
                        , Br.md [ Tw.text_9xl ]
                        , Br.sm [ Tw.text_8xl ]
                        ]
                    ]
                    [ Ui.countdown []
                        [ Tw.duration_500 ]
                        (Maybe.map2 Time.toHour shared.timeZone shared.time
                            |> Maybe.withDefault 0
                        )
                    , Dom.text ":"
                    , Ui.countdown []
                        [ Tw.duration_500 ]
                        (Maybe.map2 Time.toMinute shared.timeZone shared.time
                            |> Maybe.withDefault 0
                        )
                    , Dom.text ":"
                    , Ui.countdown []
                        [ Tw.duration_500 ]
                        (Maybe.map2 Time.toSecond shared.timeZone shared.time
                            |> Maybe.withDefault 0
                        )
                    ]
                    :: map Dom.fromUnstyled body.body
                )
    in
    { title = body.title ++ " - ResMon"
    , body =
        [ global Tw.globalStyles
        , Dom.div
            [ Attr.attribute "data-theme"
                (if shared.darkMode then
                    "dark"

                 else
                    "light"
                )
            , Attr.css
                [ Tw.bg_color Color.base_100
                , Tw.h_screen
                , Tw.flex
                , Tw.flex_col
                ]
            ]
            (alerts model.toMsg shared.alerts
                :: content
            )
        ]
            |> map Dom.toUnstyled
    }


navigation : SharedModel msg -> Model msg -> Dom.Html msg
navigation shared _ =
    Ui.navbar Dom.div
        [ Tw.bg_color Color.base_300 |> Ui.style ]
        [ Dom.div [ Attr.css [ Tw.flex_none ] ]
            [ Ui.btn Dom.button
                [ Ui.modifiers [ Ui.BtnPrimary, Ui.BtnSquare, Ui.BtnGhost ] ]
                [ Ico.list [ Tw.text_4xl ]
                ]
            ]
        , Dom.div [ Attr.css [ Tw.flex_1 ] ]
            [ Ui.btn Dom.a
                [ Ui.modifiers [ Ui.BtnLink ]
                , Attr.href "/" |> Ui.attribute
                ]
                [ Dom.img
                    [ Attr.src <|
                        if shared.darkMode then
                            "/img/logo/svg/full-text-inverted.svg"

                        else
                            "/img/logo/svg/full-text.svg"
                    , Attr.css [ Tw.h_full ]
                    ]
                    []
                ]
            ]
        , Ui.dropdown Dom.div
            [ Ui.modifier Ui.DropdownEnd ]
            [ Ui.btn Dom.div
                [ Ui.modifier Ui.BtnGhost
                , [ Attr.attribute "role" "button"
                  , Attr.tabindex 0
                  ]
                    |> Ui.attributes
                ]
                [ Ico.threeDots [ Tw.text_4xl ] ]
            ]
            Dom.ul
            [ Ui.styles
                [ Tw.mt_3
                , Tw.p_2
                , Tw.shadow_md
                , Tw.bg_color Color.base_300
                , Tw.rounded_box
                , Tw.w_52
                , Tw.z_10
                ]
            , Ui.classes
                [ Ui.menuStyle [ Ui.MenuLg ]
                ]
            ]
            [ Ui.menuItem []
                [ Dom.span
                    [ onClick (setDarkModeMessage shared (not shared.darkMode))
                    ]
                    [ Ui.swap
                        [ Ui.modifier Ui.SwapRotate
                        ]
                        [ Ico.sunFill [] ]
                        [ Ico.moonFill [] ]
                        []
                        Nothing
                        shared.darkMode
                    , Dom.text <|
                        if shared.darkMode then
                            "Light-Mode"

                        else
                            "Dark-Mode"
                    ]
                ]
            ]
        ]


footer : SharedModel msg -> Model msg -> Dom.Html msg
footer _ _ =
    Dom.div [ Attr.css [ Tw.bg_color Color.base_300, Tw.p_4 ] ]
        []


alerts : (Msg msg -> msg) -> List (Model.Shared.Alert msg) -> Dom.Html msg
alerts toMsg items =
    Ui.toast
        [ Ui.modifiers [ Ui.ToastTop, Ui.ToastEnd ] ]
        (map (alert toMsg) items)


alert : (Msg msg -> msg) -> Model.Shared.Alert msg -> Dom.Html msg
alert toMsg item =
    let
        ( ico, alertModifier, btnModifier ) =
            case item.level of
                AlertNone ->
                    ( Ico.infoCircle
                    , []
                    , [ Ui.BtnPrimary ]
                    )

                AlertInfo ->
                    ( Ico.infoCircle
                    , [ Ui.AlertInfo ]
                    , [ Ui.BtnInfo ]
                    )

                AlertSuccess ->
                    ( Ico.checkCircle
                    , [ Ui.AlertSuccess ]
                    , [ Ui.BtnSuccess ]
                    )

                AlertWarning ->
                    ( Ico.exclamationTriangle
                    , [ Ui.AlertWarning ]
                    , [ Ui.BtnWarning ]
                    )

                AlertError ->
                    ( Ico.xCircle
                    , [ Ui.AlertError ]
                    , [ Ui.BtnError ]
                    )
    in
    Ui.alert [ Ui.modifiers alertModifier, Ui.class Cls.shadow_lg ]
        [ ico [ Tw.text_3xl ]
        , Dom.div []
            [ Dom.h3 [ Attr.css [ Tw.font_bold, Tw.text_xl ] ] item.title
            , Dom.div [] item.message
            ]
        , Ui.btn Dom.button
            [ Ui.modifiers btnModifier
            , Ui.attribute <| onClick (RemoveAlert item.number |> toMsg)
            ]
            [ Dom.text "Löschen"
            ]
        ]
