port module Api exposing (Model, Msg, SubscriptionStatus(..), init, subscriptions, update)

{-| This module is a facade for the API of the application.
It is responsible for initializing the API and keeping its state.

The API is composed of multiple modules,
each responsible for a specific part of the application.

This module also contains ports to communicate with the Elm runtime.
API requests are sent to the server through a websocket connection.

@docs Model, Msg, SubscriptionStatus, init, subscriptions, update

-}

import Api.General
import Api.WorkClock
import Graph.Subscription exposing (general)
import Graphql.Document
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
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
    , general : Api.General.Model
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
        ( general, generalCmd ) =
            Api.General.init
                (subscribe GeneralModule)

        ( workClock, workClockCmd ) =
            Api.WorkClock.init
                (subscribe WorkClockModule)
                (query WorkClockModule)
                (mutate WorkClockModule)
    in
    ( { toMsg = toMsg
      , status = NotConnected
      , workClock = workClock
      , general = general
      }
    , Cmd.batch
        [ workClockCmd
        , generalCmd
        ]
    )


{-| The messages of the API.
It can be used to forward messages from the application to the API.
-}
type Msg msg
    = SubscriptionDataReceived Json.Decode.Value
    | QueryDataReceived Json.Decode.Value
    | MutationDataReceived Json.Decode.Value
    | NewSubscriptionStatus SubscriptionStatus


type ApiModule
    = WorkClockModule
    | GeneralModule


moduleEncoder : ApiModule -> Json.Encode.Value
moduleEncoder apiModule =
    let
        string : String
        string =
            case apiModule of
                WorkClockModule ->
                    "WorkClock"

                GeneralModule ->
                    "General"
    in
    Json.Encode.string string


moduleDecoder : Json.Decode.Decoder ApiModule
moduleDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\string ->
                case string of
                    "General" ->
                        Json.Decode.succeed GeneralModule

                    "WorkClock" ->
                        Json.Decode.succeed WorkClockModule

                    name ->
                        ([ "API module with the name '"
                         , name
                         , "' is not recognized."
                         ]
                            |> String.concat
                        )
                            |> Json.Decode.fail
            )


moduleFieldDecoder : Json.Decode.Decoder ApiModule
moduleFieldDecoder =
    Json.Decode.field "module" moduleDecoder


dataFieldDecoder : Json.Decode.Decoder Json.Decode.Value
dataFieldDecoder =
    Json.Decode.field "data" Json.Decode.value


apiDecoder : Json.Decode.Decoder ( ApiModule, Json.Decode.Value )
apiDecoder =
    Json.Decode.map2
        (\apiModule data ->
            ( apiModule, data )
        )
        moduleFieldDecoder
        dataFieldDecoder


subscriptionsDecoder :
    Model msg
    -> ( ApiModule, Json.Decode.Value )
    -> Result Json.Decode.Error ( Model msg, Cmd msg )
subscriptionsDecoder model ( apiModule, data ) =
    let
        result : Json.Decode.Decoder ( Model msg, Cmd msg )
        result =
            case apiModule of
                WorkClockModule ->
                    Api.WorkClock.subscriptionDecoder model.workClock
                        |> Json.Decode.map
                            (\( workClock, cmd ) ->
                                ( { model | workClock = workClock }
                                , cmd
                                )
                            )

                GeneralModule ->
                    Api.General.subscriptionDecoder model.general
                        |> Json.Decode.map
                            (\( general, cmd ) ->
                                ( { model | general = general }
                                , cmd
                                )
                            )
    in
    Json.Decode.decodeValue result data


queryDecoder :
    Model msg
    -> ( ApiModule, Json.Decode.Value )
    -> Result Json.Decode.Error ( Model msg, Cmd msg )
queryDecoder model ( apiModule, data ) =
    let
        result : Json.Decode.Decoder ( Model msg, Cmd msg )
        result =
            case apiModule of
                WorkClockModule ->
                    Api.WorkClock.queryDecoder model.workClock
                        |> Json.Decode.map
                            (\( workClock, cmd ) ->
                                ( { model | workClock = workClock }
                                , cmd
                                )
                            )

                GeneralModule ->
                    Api.General.queryDecoder model.general
                        |> Json.Decode.map
                            (\( general, cmd ) ->
                                ( { model | general = general }
                                , cmd
                                )
                            )
    in
    Json.Decode.decodeValue result data


mutationDecoder :
    Model msg
    -> ( ApiModule, Json.Decode.Value )
    -> Result Json.Decode.Error ( Model msg, Cmd msg )
mutationDecoder model ( apiModule, data ) =
    let
        result : Json.Decode.Decoder ( Model msg, Cmd msg )
        result =
            case apiModule of
                WorkClockModule ->
                    Api.WorkClock.mutationDecoder model.workClock
                        |> Json.Decode.map
                            (\( workClock, cmd ) ->
                                ( { model | workClock = workClock }
                                , cmd
                                )
                            )

                GeneralModule ->
                    Api.General.mutationDecoder model.general
                        |> Json.Decode.map
                            (\( general, cmd ) ->
                                ( { model | general = general }
                                , cmd
                                )
                            )
    in
    Json.Decode.decodeValue result data



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
        SubscriptionDataReceived rawData ->
            let
                decodedResult :
                    Result
                        Json.Decode.Error
                        (Result
                            Json.Decode.Error
                            ( Model msg, Cmd msg )
                        )
                decodedResult =
                    Json.Decode.decodeValue decoder rawData

                decoder :
                    Json.Decode.Decoder
                        (Result
                            Json.Decode.Error
                            ( Model msg, Cmd msg )
                        )
                decoder =
                    apiDecoder
                        |> Json.Decode.map
                            (subscriptionsDecoder model)
            in
            case decodedResult of
                Ok (Ok ( updatedModel, cmd )) ->
                    ( updatedModel, cmd )

                Ok (Err error) ->
                    handleError error model

                Err error ->
                    handleError error model

        QueryDataReceived rawData ->
            let
                decodedResult :
                    Result
                        Json.Decode.Error
                        (Result
                            Json.Decode.Error
                            ( Model msg, Cmd msg )
                        )
                decodedResult =
                    Json.Decode.decodeValue decoder rawData

                decoder :
                    Json.Decode.Decoder
                        (Result
                            Json.Decode.Error
                            ( Model msg, Cmd msg )
                        )
                decoder =
                    apiDecoder
                        |> Json.Decode.map
                            (queryDecoder model)
            in
            case decodedResult of
                Ok (Ok ( updatedModel, cmd )) ->
                    ( updatedModel, cmd )

                Ok (Err error) ->
                    handleError error model

                Err error ->
                    handleError error model

        MutationDataReceived rawData ->
            let
                decodedResult :
                    Result
                        Json.Decode.Error
                        (Result
                            Json.Decode.Error
                            ( Model msg, Cmd msg )
                        )
                decodedResult =
                    Json.Decode.decodeValue decoder rawData

                decoder :
                    Json.Decode.Decoder
                        (Result
                            Json.Decode.Error
                            ( Model msg, Cmd msg )
                        )
                decoder =
                    apiDecoder
                        |> Json.Decode.map
                            (mutationDecoder model)
            in
            case decodedResult of
                Ok (Ok ( updatedModel, cmd )) ->
                    ( updatedModel, cmd )

                Ok (Err error) ->
                    handleError error model

                Err error ->
                    handleError error model

        NewSubscriptionStatus status ->
            ( { model | status = status }, Cmd.none )


handleError : Json.Decode.Error -> Model msg -> ( Model msg, Cmd msg )
handleError _ model =
    ( model, Cmd.none )



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
        , gotQueryData QueryDataReceived
        , gotMutationData MutationDataReceived
        , socketStatusConnected (\_ -> NewSubscriptionStatus Connected)
        , socketStatusReconnecting (\_ -> NewSubscriptionStatus Reconnecting)
        ]
        |> Sub.map model.toMsg



-- ADAPTERS


requestObject : ApiModule -> String -> Json.Encode.Value
requestObject apiModule q =
    Json.Encode.object
        [ ( "query", Json.Encode.string q )
        , ( "module", moduleEncoder apiModule )
        ]


subscribe : ApiModule -> SelectionSet decodesTo RootSubscription -> Cmd msg
subscribe apiModule subscription =
    createSubscriptions
        (requestObject apiModule (Graphql.Document.serializeSubscription subscription))


query : ApiModule -> SelectionSet decodesTo RootQuery -> Cmd msg
query apiModule q =
    sendQuery
        (requestObject apiModule (Graphql.Document.serializeQuery q))


mutate : ApiModule -> SelectionSet decodesTo RootMutation -> Cmd msg
mutate apiModule q =
    sendMutation
        (requestObject apiModule (Graphql.Document.serializeMutation q))



-- PORTS


port sendQuery : Json.Encode.Value -> Cmd msg


port gotQueryData : (Json.Decode.Value -> msg) -> Sub msg


port sendMutation : Json.Encode.Value -> Cmd msg


port gotMutationData : (Json.Decode.Value -> msg) -> Sub msg


port createSubscriptions : Json.Encode.Value -> Cmd msg


port gotSubscriptionData : (Json.Decode.Value -> msg) -> Sub msg


port socketStatusConnected : (Json.Decode.Value -> msg) -> Sub msg


port socketStatusReconnecting : (Json.Decode.Value -> msg) -> Sub msg
