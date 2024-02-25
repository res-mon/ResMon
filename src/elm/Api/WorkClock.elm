module Api.WorkClock exposing (Activity, Model, Msg(..), WorkClock, init, update)

{-| The work clock API section.

@docs Activity, Model, Msg, WorkClock, init, update

-}

import Api.General exposing (State(..))
import Graph.Object
import Graph.Object.ActivityQuery
import Graph.Object.WorkClockQuery
import Graph.Subscription as Sub
import Graphql.Document
import Graphql.Operation exposing (RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Json.Decode



-- MODEL


{-| The model of the work clock API section.

**Fields**:

  - `toMsg` - A function to convert the API messages to the application messages.
  - `workClock` - The state of the work clock.

-}
type alias Model msg =
    { toMsg : Msg msg -> msg
    , workClock : State WorkClock
    }


{-| The initial model of the work clock API section.

**Arguments**:

  - `toMsg` - A function to convert the API messages to the application messages.

**Returns**:

  - The initial model of the work clock API section.
  - The selection set for the work clock subscription.

-}
init : (Msg msg -> msg) -> ( Model msg, SelectionSet WorkClock RootSubscription )
init toMsg =
    ( { toMsg = toMsg, workClock = Unknown }
    , workClockSubscription
    )



-- API MODEL


{-| The work clock model.

**Fields**:

  - `acticity` - The activity of the work clock.

-}
type alias WorkClock =
    { acticity : Activity
    }


{-| The activity model.

**Fields**:

  - `active` - Determines if the work clock is active or not.

-}
type alias Activity =
    { active : Bool
    }


workClockSubscription : SelectionSet WorkClock RootSubscription
workClockSubscription =
    Sub.workClock workClockSelection


workClockSelection : SelectionSet WorkClock Graph.Object.WorkClockQuery
workClockSelection =
    SelectionSet.succeed (\acticity -> { acticity = acticity })
        |> with (Graph.Object.WorkClockQuery.activity activitySelection)


activitySelection : SelectionSet Activity Graph.Object.ActivityQuery
activitySelection =
    SelectionSet.succeed (\active -> { active = active })
        |> with Graph.Object.ActivityQuery.active



-- UPDATE


{-| The messages of the work clock API section.

**Types**:

  - `SubscriptionDataReceived` - The message to handle the received subscription data.

-}
type Msg msg
    = SubscriptionDataReceived Json.Decode.Value


{-| Update the model of the work clock API section.

**Arguments**:

  - `msg` - The message to handle.
  - `model` - The current model of the work clock API section.

**Returns**:

  - The new model of the work clock API section.
  - The error if the message handling failed.
  - The command to execute.

-}
update : Msg msg -> Model msg -> ( Model msg, Maybe Json.Decode.Error, Cmd msg )
update msg model =
    case msg of
        SubscriptionDataReceived json ->
            let
                decoder : Json.Decode.Decoder WorkClock
                decoder =
                    Graphql.Document.decoder workClockSubscription

                result : Result Json.Decode.Error WorkClock
                result =
                    Json.Decode.decodeValue decoder json
            in
            case result of
                Ok workClock ->
                    ( { model | workClock = Received workClock }
                    , Nothing
                    , Cmd.none
                    )

                Err error ->
                    ( model, Just error, Cmd.none )
