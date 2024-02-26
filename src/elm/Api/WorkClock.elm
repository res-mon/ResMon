module Api.WorkClock exposing (Activity, Model, WorkClock, init, subscriptionDecoder)

{-| The work clock API section.

@docs Activity, Model, WorkClock, init, subscriptionDecoder

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

  - `acticity` - The activity of the work clock.

-}
type alias Model =
    { acticity : State Activity
    }


{-| The initial model of the work clock API section.

**Arguments**:

  - `subscribe` - A function to convert a selection set to a command.

**Returns**:

  - The initial model of the work clock API section.
  - A command containing the subscription to the work clock API section.

-}
init :
    (SelectionSet WorkClock RootSubscription -> Cmd msg)
    -> ( Model, Cmd msg )
init subscribe =
    ( { acticity = Unknown }
    , subscribe workClockSubscription
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



-- DECODER


{-| The subscription decoder of the work clock API section.
This decoder is used to decode the subscription response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

      - A decoder to update the work clock API section.

-}
subscriptionDecoder : Model -> Json.Decode.Decoder ( Model, Cmd msg )
subscriptionDecoder model =
    Graphql.Document.decoder workClockSubscription
        |> Json.Decode.map
            (\workClock ->
                ( { model | acticity = Received workClock.acticity }
                , Cmd.none
                )
            )
