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
import Dict
import Dict.Extra
import Extension.Time exposing (monthToInt, sameDay)
import Html.Styled as Dom exposing (toUnstyled)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import List exposing (map)
import Maybe exposing (withDefault)
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
        , Dom.div
            []
            [ case shared.api.workClock.history of
                Api.Shared.Unknown ->
                    Dom.text "Lade Stempeluhrhistorie..."

                Api.Shared.Received history ->
                    historyView
                        shared.timeZone
                        shared.time
                        history.historyItems
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
                    Component.Time.deltaClock
                        (Just activity.since)
                        (Just time)

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


historyView :
    Maybe Time.Zone
    -> Maybe Time.Posix
    -> List Api.WorkClock.HistoryItem
    -> Dom.Html msg
historyView zone now history =
    let
        groupedHistory : List (List Api.WorkClock.HistoryItem)
        groupedHistory =
            groupHistoryItemsByDay zone history
                |> map (List.sortBy (\item -> Time.posixToMillis item.start))

        itemView : List Api.WorkClock.HistoryItem -> List (Dom.Html msg)
        itemView items =
            let
                maybeFirst : Maybe Api.WorkClock.HistoryItem
                maybeFirst =
                    List.head items
            in
            case maybeFirst of
                Just first ->
                    historyItemGroupView zone now first items

                Nothing ->
                    []
    in
    Dom.div
        [ Attr.css
            [ Tw.my_8
            , Tw.overflow_x_auto
            ]
        ]
        [ Ui.table
            [ Ui.modifiers
                [ Ui.TableZebra
                , Ui.TablePinRows
                ]
            ]
            [ Dom.text "Datum"
            , Dom.text "Start-Zeit"
            , Dom.text "End-Zeit"
            , Dom.text "Dauer"
            ]
            (map itemView groupedHistory)
            []
        ]


historyItemGroupView :
    Maybe Time.Zone
    -> Maybe Time.Posix
    -> Api.WorkClock.HistoryItem
    -> List Api.WorkClock.HistoryItem
    -> List (Dom.Html msg)
historyItemGroupView zone now first items =
    let
        itemEnd : Api.WorkClock.HistoryItem -> Maybe Time.Posix
        itemEnd item =
            case item.end of
                Just e ->
                    Just e

                Nothing ->
                    now

        itemStart : Api.WorkClock.HistoryItem -> Maybe Time.Posix
        itemStart item =
            Just item.start
    in
    [ Dom.div [] (Component.Time.date zone (Just first.start))
    , Dom.div []
        (map
            (\item ->
                Dom.div []
                    (Component.Time.clock zone (itemStart item))
            )
            items
        )
    , Dom.div []
        (map
            (\item ->
                Dom.div []
                    (List.concat
                        [ if
                            Maybe.map3 sameDay
                                zone
                                (itemStart item)
                                (itemEnd item)
                                |> withDefault False
                          then
                            []

                          else
                            List.concat
                                [ Component.Time.date zone (itemEnd item)
                                , [ Dom.text ", " ]
                                ]
                        , Component.Time.clock zone (itemEnd item)
                        ]
                    )
            )
            items
        )
    , Dom.div []
        (Component.Time.durationClock
            (map
                (\item ->
                    (Maybe.map Time.posixToMillis
                        (itemEnd item)
                        |> withDefault 0
                    )
                        - (Maybe.map Time.posixToMillis
                            (itemStart item)
                            |> withDefault 0
                          )
                )
                items
                |> List.sum
            )
        )
    ]


groupHistoryItemsByDay : Maybe Time.Zone -> List Api.WorkClock.HistoryItem -> List (List Api.WorkClock.HistoryItem)
groupHistoryItemsByDay zone items =
    Dict.Extra.groupBy
        (\item ->
            let
                day : Int
                day =
                    Maybe.map2 Time.toDay zone (Just item.start)
                        |> withDefault 0

                month : Int
                month =
                    Maybe.map2
                        (\z t ->
                            Time.toMonth z t
                                |> monthToInt
                        )
                        zone
                        (Just item.start)
                        |> withDefault 0

                year : Int
                year =
                    Maybe.map2 Time.toYear zone (Just item.start)
                        |> withDefault 0
            in
            year * 10000 + month * 100 + day
        )
        items
        |> Dict.toList
        |> List.sortBy Tuple.first
        |> map Tuple.second
        |> List.reverse
