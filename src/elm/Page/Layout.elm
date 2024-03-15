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
                    [ Tw.p_1
                    , Tw.bg_color Color.base_100
                    , Tw.text_color Color.base_content
                    , Tw.flex_1
                    , Tw.overflow_auto
                    , Br.xxl [ Tw.p_16 ]
                    , Br.xl [ Tw.p_10 ]
                    , Br.md [ Tw.p_6 ]
                    , Br.sm [ Tw.p_4 ]
                    ]
                ]
                (map Dom.fromUnstyled body.body)
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
