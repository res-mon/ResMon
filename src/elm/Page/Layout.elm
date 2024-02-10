module Page.Layout exposing (Model, Msg, init, update, view)

import Browser exposing (Document)
import Component.DaisyUi as D exposing (SwapModifier(..), class, modifier)
import Component.Icon as Icon
import Css.Global exposing (global)
import Html.Styled exposing (Html, button, div, fromUnstyled, h3, main_, text, toUnstyled)
import Html.Styled.Attributes exposing (attribute, css)
import Html.Styled.Events exposing (onClick)
import List exposing (map)
import Model.Shared exposing (AlertLevel(..), SharedModel, removeAlert, setDarkModeMessage)
import Tailwind.Classes exposing (shadow_lg)
import Tailwind.Theme exposing (base_100)
import Tailwind.Utilities
    exposing
        ( bg_color
        , duration_500
        , float_right
        , font_bold
        , font_mono
        , globalStyles
        , grid
        , h_screen
        , m_4
        , p_16
        , place_items_center
        , text_3xl
        , text_4xl
        , text_7xl
        , text_xl
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
view shared model _ body =
    let
        content : List (Html msg)
        content =
            [ D.swap
                [ modifier SwapRotate
                , class ( [ text_4xl, float_right, m_4 ], [] )
                ]
                [ Icon.sunFill [] ]
                [ Icon.moonFill [] ]
                []
                (setDarkModeMessage shared)
                shared.darkMode
            , mainElement
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
