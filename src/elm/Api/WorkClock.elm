module Api.WorkClock exposing (Activity, Model, WorkClock, init, subscriptionDecoder, Internal, mutationDecoder, queryDecoder, setWorkClockActive, History, HistoryItem)

{-| The work clock API section.

@docs Activity, Model, WorkClock, init, subscriptionDecoder, Internal, mutationDecoder, queryDecoder, setWorkClockActive, History, HistoryItem

-}

import Api.Shared exposing (State(..))
import Graph.Mutation as Mut
import Graph.Object
import Graph.Object.ActivityMutation exposing (SetActiveRequiredArguments)
import Graph.Object.ActivityQuery
import Graph.Object.HistoryItem
import Graph.Object.HistoryQuery
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
    , history : State History
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
    , workClockMutation : SelectionSet Activity RootMutation -> Cmd msg
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
    -> (SelectionSet Activity RootMutation -> Cmd msg)
    -> ( Model msg, Cmd msg )
init workClockSubscriptionHandler workClockQueryHandler workClockMutationHandler =
    ( { activity = Unknown
      , history = Unknown
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
      - `history` - The history of the work clock.

-}
type alias WorkClock =
    { activity : Activity
    , history : History
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


{-| The history model.

**Fields**:

  - `historyItems` - The history items of the work clock.

-}
type alias History =
    { historyItems : List HistoryItem
    }


{-| A history item.

**Fields**:

  - `start` - The start time of a history item.
  - `since` - The end time of a history item. If nothing, the history item is still active.

-}
type alias HistoryItem =
    { start : Posix
    , end : Maybe Posix
    }


workClockQuery : SelectionSet WorkClock RootQuery
workClockQuery =
    Query.workClock workClockSelection


workClockMutation : SetActiveRequiredArguments -> SelectionSet Activity RootMutation
workClockMutation args =
    Mut.workClock (workClockUpdate args)


workClockSubscription : SelectionSet WorkClock RootSubscription
workClockSubscription =
    Sub.workClock workClockSelection


workClockUpdate : SetActiveRequiredArguments -> SelectionSet Activity Graph.Object.WorkClockMutation
workClockUpdate args =
    SelectionSet.succeed (\activity -> activity)
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
    SelectionSet.succeed
        (\activity history ->
            { activity = activity
            , history = history
            }
        )
        |> with (Graph.Object.WorkClockQuery.activity activitySelection)
        |> with (Graph.Object.WorkClockQuery.history historySelection)


activitySelection : SelectionSet Activity Graph.Object.ActivityQuery
activitySelection =
    SelectionSet.succeed (\active since -> { active = active, since = since })
        |> with Graph.Object.ActivityQuery.active
        |> with Graph.Object.ActivityQuery.since


historySelection : SelectionSet History Graph.Object.HistoryQuery
historySelection =
    SelectionSet.succeed (\historyItems -> { historyItems = historyItems })
        |> with
            (Graph.Object.HistoryQuery.historyItems (\args -> args)
                historyItemSelection
            )


historyItemSelection : SelectionSet HistoryItem Graph.Object.HistoryItem
historyItemSelection =
    SelectionSet.succeed (\start end -> { start = start, end = end })
        |> with Graph.Object.HistoryItem.start
        |> with Graph.Object.HistoryItem.end



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
                ( { model
                    | activity = Received workClock.activity
                    , history = Received workClock.history
                  }
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
            (\activity ->
                ( { model | activity = Received activity }
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
                ( { model
                    | activity = Received workClock.activity
                    , history = Received workClock.history
                  }
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
