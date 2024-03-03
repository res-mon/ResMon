module Page.WorkClock exposing (Model, Msg, init, update, view)

{-| The work clock page.

@docs Model, Msg, init, update, view

-}

import Api
import Api.Shared
import Api.WorkClock
import Browser exposing (Document)
import Component.DaisyUi as Ui
import Component.Time
import Html.Styled as Dom exposing (toUnstyled)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import List exposing (map)
import Model.Shared
    exposing
        ( SharedModel
        )
import Page.Layout exposing (Msg)
import Tailwind.Breakpoints as Br
import Tailwind.Utilities as Tw
import Time



-- MODEL


{-| The model for the work clock page.

**Fields:**

  - `toMsg` - A function to convert a `Msg` to a `Msg` that can be sent to the parent page.

-}
type alias Model msg =
    { toMsg : Msg msg -> msg
    }


{-| The initial model for the work clock page.

**Arguments:**

  - `toMsg` - A function to convert a `Msg` to a `Msg` that can be sent to the parent page.
  - `shared` - The shared model.

**Returns:**

  - The initial model for the work clock page.
  - A command to run when the page is initialized.

-}
init : (Msg msg -> msg) -> SharedModel msg -> ( Model msg, Cmd msg )
init toMsg _ =
    ( { toMsg = toMsg }, Cmd.none )



-- UPDATE


{-| The messages that can be sent to the work clock page.
-}
type Msg msg
    = SetActive
    | SetInactive


{-| The update function for the work clock page.

**Arguments:**

  - `msg` - The message to process.
  - `shared` - The shared model.
  - `model` - The model for the work clock page.

**Returns:**

    - The updated shared model.
    - The updated model for the work clock page.
    - A command to run after the update.

-}
update :
    Msg msg
    -> SharedModel msg
    -> Model msg
    -> ( SharedModel msg, Model msg, Cmd msg )
update msg shared model =
    case msg of
        SetActive ->
            ( shared
            , model
            , Api.WorkClock.setWorkClockActive shared.api.workClock True
            )

        SetInactive ->
            ( shared
            , model
            , Api.WorkClock.setWorkClockActive shared.api.workClock False
            )



-- VIEW


{-| The view for the work clock page.

**Arguments:**

  - `shared` - The shared model.
  - `model` - The model for the work clock page.

**Returns:**

      - The document for the work clock page.

-}
view : SharedModel msg -> Model msg -> Document msg
view shared model =
    { title = "Stempeluhr"
    , body =
        [ Dom.div
            [ Attr.css
                [ Tw.text_5xl
                , Tw.font_mono
                , Tw.text_center
                , Br.xl [ Tw.text_9xl ]
                , Br.sm [ Tw.text_8xl ]
                ]
            ]
            (Component.Time.clock
                shared.timeZone
                shared.time
            )
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
            |> map toUnstyled
    }


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
                let
                    ( displayText, clickMessage ) =
                        if activity.active then
                            ( "Abstempeln", SetInactive )

                        else
                            ( "Einstempeln", SetActive )
                in
                [ Ui.btn Dom.button
                    [ Ui.modifiers
                        [ if activity.active then
                            Ui.BtnError

                          else
                            Ui.BtnSuccess
                        ]
                    , onClick
                        (model.toMsg clickMessage)
                        |> Ui.attribute
                    ]
                    [ Dom.text displayText
                    ]
                ]
        )
