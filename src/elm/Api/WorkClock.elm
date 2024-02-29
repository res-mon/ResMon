module Api.WorkClock exposing (Activity, Model, WorkClock, init, subscriptionDecoder, Internal, mutationDecoder, queryDecoder, setWorkClockActive)

{-| The work clock API section.

@docs Activity, Model, WorkClock, init, subscriptionDecoder, Internal, mutationDecoder, queryDecoder, setWorkClockActive

-}

import Api.Shared exposing (State(..))
import Graph.Mutation as Mut
import Graph.Object
import Graph.Object.ActivityMutation exposing (SetActiveRequiredArguments)
import Graph.Object.ActivityQuery
import Graph.Object.WorkClockMutation
import Graph.Object.WorkClockQuery
import Graph.Query as Query
import Graph.Subscription as Sub
import Graphql.Document
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Json.Decode
import Time exposing (Posix)



-- MODEL


{-| The model of the work clock API section.

**Fields**:

  - `activity` - The activity of the work clock.

-}
type alias Model msg =
    { activity : State Activity
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
    ( { activity = Unknown
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

  - `activity` - The activity of the work clock.

-}
type alias WorkClock =
    { activity : Activity
    }


{-| The activity model.

**Fields**:

  - `active` - Determines if the work clock is active or not.
  - `since` - The time when the work clock was last changed.

-}
type alias Activity =
    { active : Bool
    , since : Posix
    }


workClockQuery : SelectionSet WorkClock RootQuery
workClockQuery =
    Query.workClock workClockSelection


workClockMutation : SetActiveRequiredArguments -> SelectionSet WorkClock RootMutation
workClockMutation args =
    Mut.workClock (workClockUpdate args)


workClockSubscription : SelectionSet WorkClock RootSubscription
workClockSubscription =
    Sub.workClock workClockSelection


workClockUpdate : SetActiveRequiredArguments -> SelectionSet WorkClock Graph.Object.WorkClockMutation
workClockUpdate args =
    SelectionSet.succeed (\activity -> { activity = activity })
        |> with
            (Graph.Object.WorkClockMutation.activity
                (activityUpdate args)
            )


activityUpdate : SetActiveRequiredArguments -> SelectionSet Activity Graph.Object.ActivityMutation
activityUpdate args =
    SelectionSet.succeed (\activity -> activity)
        |> with (Graph.Object.ActivityMutation.setActive args activitySelection)


workClockSelection : SelectionSet WorkClock Graph.Object.WorkClockQuery
workClockSelection =
    SelectionSet.succeed (\activity -> { activity = activity })
        |> with (Graph.Object.WorkClockQuery.activity activitySelection)


activitySelection : SelectionSet Activity Graph.Object.ActivityQuery
activitySelection =
    SelectionSet.succeed (\active since -> { active = active, since = since })
        |> with Graph.Object.ActivityQuery.active
        |> with Graph.Object.ActivityQuery.since



-- DECODER


{-| The query decoder of the work clock API section.
This decoder is used to decode the query response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

  - A decoder to update the work clock API section model.

-}
queryDecoder : Model msg -> Json.Decode.Decoder ( Model msg, Cmd msg )
queryDecoder model =
    Graphql.Document.decoder workClockQuery
        |> Json.Decode.map
            (\workClock ->
                ( { model | activity = Received workClock.activity }
                , Cmd.none
                )
            )


{-| The mutation decoder of the work clock API section.
This decoder is used to decode the mutation response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

    - A decoder to update the work clock API section model.

-}
mutationDecoder : Model msg -> Json.Decode.Decoder ( Model msg, Cmd msg )
mutationDecoder model =
    Graphql.Document.decoder (workClockMutation { active = False })
        |> Json.Decode.map
            (\workClock ->
                ( { model | activity = Received workClock.activity }
                , Cmd.none
                )
            )


{-| The subscription decoder of the work clock API section.
This decoder is used to decode the subscription response of the work clock API section.

**Arguments**:

  - `model` - The model of the work clock API section.

**Returns**:

  - A decoder to update the work clock API section model.

-}
subscriptionDecoder : Model msg -> Json.Decode.Decoder ( Model msg, Cmd msg )
subscriptionDecoder model =
    Graphql.Document.decoder workClockSubscription
        |> Json.Decode.map
            (\workClock ->
                ( { model | activity = Received workClock.activity }
                , Cmd.none
                )
            )



-- COMMANDS


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
            { active = active }
        )
