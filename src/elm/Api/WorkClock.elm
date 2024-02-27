module Api.WorkClock exposing (Activity, Model, WorkClock, init, subscriptionDecoder, Internal, mutationDecoder, queryDecoder, queryWorkClock, setWorkClockActive)

{-| The work clock API section.

@docs Activity, Model, WorkClock, init, subscriptionDecoder, Internal, mutationDecoder, queryDecoder, queryWorkClock, setWorkClockActive

-}

import Api.General exposing (State(..))
import Graph.Mutation as Mut
import Graph.Object
import Graph.Object.ActivityMutation
import Graph.Object.ActivityQuery
import Graph.Object.WorkClockMutation
import Graph.Object.WorkClockQuery
import Graph.Query as Query
import Graph.Subscription as Sub
import Graphql.Document
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Json.Decode



-- MODEL


{-| The model of the work clock API section.

**Fields**:

  - `acticity` - The activity of the work clock.

-}
type alias Model msg =
    { acticity : State Activity
    , internal : Internal msg
    }


{-| The internal model of the work clock API section.
-}
type Internal msg
    = Internal (InternalModel msg)


unbox : Internal msg -> InternalModel msg
unbox (Internal model) =
    model


type alias InternalModel msg =
    { workClockQuery : SelectionSet WorkClock RootQuery -> Cmd msg
    , workClockMutation : SelectionSet WorkClock RootMutation -> Cmd msg
    }


{-| The initial model of the work clock API section.

**Arguments**:

  - `workClockSubscriptionHandler` - The subscription handler of the work clock API section.
  - `workClockQueryHandler` - The query handler of the work clock API section.
  - `workClockMutationHandler` - The mutation handler of the work clock API section.

**Returns**:

  - The initial model of the work clock API section.
  - A command containing the subscription to the work clock API section.

-}
init :
    (SelectionSet WorkClock RootSubscription -> Cmd msg)
    -> (SelectionSet WorkClock RootQuery -> Cmd msg)
    -> (SelectionSet WorkClock RootMutation -> Cmd msg)
    -> ( Model msg, Cmd msg )
init workClockSubscriptionHandler workClockQueryHandler workClockMutationHandler =
    ( { acticity = Unknown
      , internal =
            Internal
                { workClockQuery = workClockQueryHandler
                , workClockMutation = workClockMutationHandler
                }
      }
    , workClockSubscriptionHandler workClockSubscription
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


workClockQuery : SelectionSet WorkClock RootQuery
workClockQuery =
    Query.workClock workClockSelection


workClockMutation : WorkClock -> SelectionSet WorkClock RootMutation
workClockMutation workClock =
    Mut.workClock (workClockUpdate workClock)


workClockSubscription : SelectionSet WorkClock RootSubscription
workClockSubscription =
    Sub.workClock workClockSelection


workClockUpdate : WorkClock -> SelectionSet WorkClock Graph.Object.WorkClockMutation
workClockUpdate workClock =
    SelectionSet.succeed (\acticity -> { acticity = acticity })
        |> with
            (Graph.Object.WorkClockMutation.activity
                (activityUpdate workClock.acticity)
            )


activityUpdate : Activity -> SelectionSet Activity Graph.Object.ActivityMutation
activityUpdate acticity =
    SelectionSet.succeed (\active -> { active = active })
        |> with (Graph.Object.ActivityMutation.setActive acticity)


workClockSelection : SelectionSet WorkClock Graph.Object.WorkClockQuery
workClockSelection =
    SelectionSet.succeed (\acticity -> { acticity = acticity })
        |> with (Graph.Object.WorkClockQuery.activity activitySelection)


activitySelection : SelectionSet Activity Graph.Object.ActivityQuery
activitySelection =
    SelectionSet.succeed (\active -> { active = active })
        |> with Graph.Object.ActivityQuery.active



-- DECODER


{-| The query decoder of the work clock API section.
This decoder is used to decode the query response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

  - A decoder to update the work clock API section.

-}
queryDecoder : Model msg -> Json.Decode.Decoder ( Model msg, Cmd msg )
queryDecoder model =
    Graphql.Document.decoder workClockQuery
        |> Json.Decode.map
            (\workClock ->
                ( { model | acticity = Received workClock.acticity }
                , Cmd.none
                )
            )


{-| The mutation decoder of the work clock API section.
This decoder is used to decode the mutation response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

    - A decoder to update the work clock API section.

-}
mutationDecoder : Model msg -> Json.Decode.Decoder ( Model msg, Cmd msg )
mutationDecoder model =
    Graphql.Document.decoder (workClockMutation { acticity = { active = False } })
        |> Json.Decode.map
            (\workClock ->
                ( { model | acticity = Received workClock.acticity }
                , Cmd.none
                )
            )


{-| The subscription decoder of the work clock API section.
This decoder is used to decode the subscription response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

      - A decoder to update the work clock API section.

-}
subscriptionDecoder : Model msg -> Json.Decode.Decoder ( Model msg, Cmd msg )
subscriptionDecoder model =
    Graphql.Document.decoder workClockSubscription
        |> Json.Decode.map
            (\workClock ->
                ( { model | acticity = Received workClock.acticity }
                , Cmd.none
                )
            )



-- COMMANDS


{-| Query the work clock state.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

    - A command to query the work clock state.

-}
queryWorkClock : Model msg -> Cmd msg
queryWorkClock model =
    (unbox model.internal).workClockQuery workClockQuery


{-| Set the work clock active state.

**Arguments**:

  - `model` - The model of the work clock API section.
  - `active` - The active state of the work clock.

**Returns**:

    - A command to set the work clock active state.

-}
setWorkClockActive : Model msg -> Bool -> Cmd msg
setWorkClockActive model active =
    (unbox model.internal).workClockMutation
        (workClockMutation
            { acticity = { active = active }
            }
        )
