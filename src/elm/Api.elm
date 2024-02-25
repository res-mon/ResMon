port module Api exposing (Model, Msg, SubscriptionStatus(..), init, subscriptions, update)

{-| This module is a facade for the API of the application.
It is responsible for initializing the API and keeping its state.

The API is composed of multiple modules,
each responsible for a specific part of the application.

This module also contains ports to communicate with the Elm runtime.
API requests are sent to the server through a websocket connection.

@docs Model, Msg, SubscriptionStatus, init, subscriptions, update

-}

import Api.WorkClock
import Graphql.Document
import Graphql.Operation exposing (RootSubscription)
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode
import Json.Encode



-- MODEL


{-| Describe the status of the subscription to the server.

  - `NotConnected`: The subscription is not connected to the server.
  - `Connected`: The subscription is connected to the server.
  - `Reconnecting`: The subscription is trying to reconnect to the server.

-}
type SubscriptionStatus
    = NotConnected
    | Connected
    | Reconnecting


{-| The model of the API.

**Fields**:

  - `toMsg`: A function to convert the API messages to the application messages.
  - `status`: The status of the subscription to the server.
  - `workClock`: The model of the work clock API.

-}
type alias Model msg =
    { toMsg : Msg msg -> msg
    , status : SubscriptionStatus
    , workClock : Api.WorkClock.Model msg
    }


{-| Initializes the API, all its modules and
starts the subscriptions to the server.

**Arguments**:

  - `toMsg`: A function to convert the API messages to the application messages.

**Returns**:

  - The initial model.
  - A command to initialize the API.

-}
init : (Msg msg -> msg) -> ( Model msg, Cmd msg )
init toMsg =
    let
        ( workClock, workClockSubscription ) =
            Api.WorkClock.init (WorkClockMsg >> toMsg)
    in
    ( { toMsg = toMsg
      , status = NotConnected
      , workClock = workClock
      }
    , subscribe workClockSubscription
    )


{-| The messages of the API.
It can be used to forward messages from the application to the API.
-}
type Msg msg
    = SubscriptionDataReceived Json.Decode.Value
    | NewSubscriptionStatus SubscriptionStatus
    | WorkClockMsg (Api.WorkClock.Msg msg)



-- UPDATE


{-| Update the model of the API.

**Arguments**:

  - `msg`: The message to update the model.
  - `model`: The model to update.

**Returns**:

  - The updated model.
  - A command to execute.

-}
update : Msg msg -> Model msg -> ( Model msg, Cmd msg )
update msg model =
    case msg of
        SubscriptionDataReceived data ->
            let
                ( workClock, _, cmd ) =
                    Api.WorkClock.update
                        (Api.WorkClock.SubscriptionDataReceived data)
                        model.workClock
            in
            ( { model | workClock = workClock }, cmd )

        NewSubscriptionStatus status ->
            ( { model | status = status }, Cmd.none )

        WorkClockMsg workClockMsg ->
            let
                ( workClock, _, cmd ) =
                    Api.WorkClock.update workClockMsg model.workClock
            in
            ( { model | workClock = workClock }, cmd )



-- SUBSCRIPTIONS


{-| The subscriptions of the API.

**Arguments**:

  - `model`: The model of the API.

**Returns**:

  - A subscription to the API.

-}
subscriptions : Model msg -> Sub msg
subscriptions model =
    Sub.batch
        [ gotSubscriptionData SubscriptionDataReceived
        , socketStatusConnected (\_ -> NewSubscriptionStatus Connected)
        , socketStatusReconnecting (\_ -> NewSubscriptionStatus Reconnecting)
        ]
        |> Sub.map model.toMsg



-- ADAPTERS


subscribe : SelectionSet decodesTo RootSubscription -> Cmd msg
subscribe subscription =
    createSubscriptions
        (Json.Encode.string
            (subscription
                |> Graphql.Document.serializeSubscription
            )
        )



-- PORTS


port createSubscriptions : Json.Encode.Value -> Cmd msg


port gotSubscriptionData : (Json.Decode.Value -> msg) -> Sub msg


port socketStatusConnected : (Json.Decode.Value -> msg) -> Sub msg


port socketStatusReconnecting : (Json.Decode.Value -> msg) -> Sub msg
