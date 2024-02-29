module Page.Layout exposing (Model, Msg, init, update, view)

import Api
import Api.Shared
import Api.WorkClock
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
    | ToggleWorkClock


update :
    Msg msg
    -> SharedModel msg
    -> Model msg
    -> ( SharedModel msg, Model msg, Cmd msg )
update msg shared model =
    case msg of
        RemoveAlert number ->
            ( removeAlert shared number, model, Cmd.none )

        ToggleWorkClock ->
            ( shared
            , model
            , Api.WorkClock.setWorkClockActive shared.api.workClock
                (case shared.api.workClock.activity of
                    Api.Shared.Unknown ->
                        True

                    Api.Shared.Received activity ->
                        not activity.active
                )
            )



-- VIEW


view : SharedModel msg -> Model msg -> Bool -> Document msg -> Document msg
view shared model minimal body =
    let
        content : Dom.Html msg
        content =
            if minimal then
                mainElement

            else
                let
                    sidebarToggleId : String
                    sidebarToggleId =
                        "layout-sidebar-toggle"
                in
                Ui.drawer sidebarToggleId
                    [ Br.lg [ Tw.drawer_open ] |> Ui.style ]
                    [ Ui.styles
                        [ Tw.h_screen
                        , Tw.flex
                        , Tw.flex_col
                        ]
                    ]
                    [ Dom.header []
                        [ navigation shared model sidebarToggleId ]
                    , mainElement
                    , footer shared model
                    ]
                    [ Ui.menu
                        [ Ui.styles
                            [ Tw.p_4
                            , Tw.w_64
                            , Tw.min_h_full
                            , Tw.bg_color Color.base_300
                            , Tw.text_color Color.base_content
                            , Br.sm [ Tw.w_80 ]
                            ]
                        , Ui.modifier Ui.MenuLg
                        ]
                        [ Ui.menuItem [] [ resMonLogo "/" shared ]
                        , Ui.menuItem [] []
                        , Ui.menuItem []
                            [ Dom.span
                                [ onClick (setDarkModeMessage shared (not shared.darkMode))
                                , Attr.css [ Tw.cursor_pointer ]
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

        mainElement : Dom.Html msg
        mainElement =
            Dom.main_
                [ Attr.css
                    [ Tw.p_16
                    , Tw.bg_color Color.base_100
                    , Tw.text_color Color.base_content
                    , Tw.grid
                    , Tw.flex_1
                    , Tw.place_items_center
                    ]
                ]
                (Dom.div []
                    [ Dom.div
                        [ Attr.css
                            [ Tw.text_5xl
                            , Tw.font_mono
                            , Br.xl [ Tw.text_9xl ]
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
                    , Dom.div
                        [ Attr.css [ Tw.text_center ] ]
                        [ Dom.text "API Status: "
                        , Dom.text <|
                            case shared.api.status of
                                Api.NotConnected ->
                                    "Nicht verbunden"

                                Api.Connected ->
                                    "Verbunden"

                                Api.Reconnecting ->
                                    "Verbindung wird wiederhergestellt"
                        ]
                    , toggleView shared model
                    , Dom.div
                        [ Attr.css [ Tw.text_center ] ]
                        [ Dom.text "Stempeluhr: "
                        , case shared.api.workClock.activity of
                            Api.Shared.Unknown ->
                                Dom.text "Unbekannt"

                            Api.Shared.Received activity ->
                                workClockView shared activity
                        ]
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
                , Tw.text_color Color.base_content
                , Tw.h_screen
                , Tw.flex
                , Tw.flex_col
                ]
            ]
            [ alerts model.toMsg shared.alerts
            , content
            ]
        ]
            |> map Dom.toUnstyled
    }


navigation : SharedModel msg -> Model msg -> String -> Dom.Html msg
navigation _ _ sidebarToggleId =
    Ui.navbar Dom.div
        [ [ Tw.bg_color Color.base_300
          , Br.lg [ Tw.hidden ]
          ]
            |> Ui.styles
        ]
        [ Dom.div [ Attr.css [ Tw.flex_none ] ]
            [ Ui.styleElement Dom.label
                [ Ui.btnStyle
                    [ Ui.BtnPrimary
                    , Ui.BtnSquare
                    , Ui.BtnGhost
                    ]
                    |> Ui.class
                , Attr.for sidebarToggleId |> Ui.attribute
                ]
                [ Ico.list [ Tw.text_4xl ] ]
            ]
        ]


workClockView : SharedModel msg -> Api.WorkClock.Activity -> Dom.Html msg
workClockView shared activity =
    Dom.span []
        [ Dom.text <|
            if activity.active then
                "Aktiv"

            else
                "Inaktiv"
        , Dom.text " seit "
        , Dom.span []
            (case shared.time of
                Just time ->
                    let
                        duration : Int
                        duration =
                            ((Time.posixToMillis time - Time.posixToMillis activity.since)
                                |> toFloat
                            )
                                / 1000
                                |> round
                                |> max 0

                        hours : Int
                        hours =
                            duration // 3600

                        minutes : Int
                        minutes =
                            modBy 60 (duration // 60)

                        seconds : Int
                        seconds =
                            modBy 60 duration
                    in
                    [ Ui.countdown []
                        [ Tw.duration_500 ]
                        hours
                    , Dom.text ":"
                    , Ui.countdown []
                        [ Tw.duration_500 ]
                        minutes
                    , Dom.text ":"
                    , Ui.countdown []
                        [ Tw.duration_500 ]
                        seconds
                    ]

                _ ->
                    [ Dom.text "Unbekannt" ]
            )
        ]


toggleView : SharedModel msg -> Model msg -> Dom.Html msg
toggleView shared model =
    Dom.div [ Attr.css [ Tw.text_center, Tw.m_4 ] ]
        (case shared.api.workClock.activity of
            Api.Shared.Unknown ->
                []

            Api.Shared.Received activity ->
                [ Ui.btn Dom.button
                    [ Ui.modifiers
                        [ if activity.active then
                            Ui.BtnError

                          else
                            Ui.BtnSuccess
                        ]
                    , onClick (model.toMsg ToggleWorkClock) |> Ui.attribute
                    ]
                    [ Dom.text <|
                        if activity.active then
                            "Abstempeln"

                        else
                            "Einstempeln"
                    ]
                ]
        )


resMonLogo : String -> SharedModel msg -> Dom.Html msg
resMonLogo href shared =
    Ui.btn Dom.a
        [ Ui.modifiers [ Ui.BtnLink ]
        , Attr.href href |> Ui.attribute
        ]
        [ Dom.img
            [ Attr.src <|
                if shared.darkMode then
                    "/img/logo/svg/full-text-inverted.svg"

                else
                    "/img/logo/svg/full-text.svg"
            , Attr.css [ Tw.h_full, Tw.py_1 ]
            ]
            []
        ]


footer : SharedModel msg -> Model msg -> Dom.Html msg
footer shared _ =
    Dom.div
        [ Attr.css
            [ Tw.p_2
            , Tw.bg_color Color.base_300
            , Tw.text_color Color.base_content
            , Tw.text_center
            ]
        ]
        [ Ui.menu
            [ Ui.modifiers [ Ui.MenuLg, Ui.MenuHorizontal ]
            ]
            [ Ui.menuItem []
                [ Dom.a
                    [ Attr.href "https://github.com/yerTools/ResMon"
                    ]
                    [ Dom.text "GitHub-Projekt" ]
                ]
            , Ui.menuItem [] [ resMonLogo "https://resmon.de" shared ]
            , Ui.menuItem []
                [ Dom.a
                    [ Attr.href "https://docs.resmon.de/packages/yertools/res-mon/latest/"
                    ]
                    [ Dom.text "Dokumentation" ]
                ]
            ]
        ]


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
