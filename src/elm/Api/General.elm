module Api.General exposing (GeneralModel, GeneralTime, Model, init, mutationDecoder, queryDecoder, subscriptionDecoder)

{-| The general API section.

@docs GeneralModel, GeneralTime, Model, init, mutationDecoder, queryDecoder, subscriptionDecoder

-}

import Api.Shared exposing (State(..))
import Graph.Object
import Graph.Object.GeneralQuery
import Graph.Object.GeneralTimeQuery
import Graph.Subscription as Sub
import Graphql.Document
import Graphql.Operation exposing (RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Json.Decode
import Time exposing (Posix)



-- MODEL


{-| The model for the general API section.

**Fields**:

  - `time` : The current time.

-}
type alias Model =
    { time : State GeneralTime
    }


{-| The initial model and command for the general API section.

**Arguments**:

  - `generalSubscriptionHandler` : The handler for the general subscription.

**Returns**:

      - The initial model.
      - The command to subscribe to the general API section.

-}
init :
    (SelectionSet GeneralModel RootSubscription -> Cmd msg)
    -> ( Model, Cmd msg )
init generalSubscriptionHandler =
    ( { time = Unknown }
    , generalSubscriptionHandler generalSubscription
    )



-- API MODEL


{-| The general moderl.

**Fields**:

  - `time` : The general time.

-}
type alias GeneralModel =
    { time : GeneralTime
    }


{-| The general time.

**Fields**:

  - `current` : The current time.

-}
type alias GeneralTime =
    { current : Posix
    }


generalSubscription : SelectionSet GeneralModel RootSubscription
generalSubscription =
    Sub.general generalSelection


generalSelection : SelectionSet GeneralModel Graph.Object.GeneralQuery
generalSelection =
    SelectionSet.succeed (\time -> { time = time })
        |> with (Graph.Object.GeneralQuery.time timeSelection)


timeSelection : SelectionSet GeneralTime Graph.Object.GeneralTimeQuery
timeSelection =
    SelectionSet.succeed (\current -> { current = current })
        |> with Graph.Object.GeneralTimeQuery.current



-- DECODER


{-| The query decoder for the general API section.
This decoder is used to decode the query response of the general API section.

**Arguments**:

  - `model` - The model of the general API section.

**Returns**:

  - A decoder to update the general API section model.

-}
queryDecoder : Model -> Json.Decode.Decoder ( Model, Cmd msg )
queryDecoder _ =
    Json.Decode.oneOf
        []


{-| The mutation decoder for the general API section.
This decoder is used to decode the mutation response of the general API section.

**Arguments**:

  - `model` - The model of the general API section.

**Returns**:

  - A decoder to update the general API section model.

-}
mutationDecoder : Model -> Json.Decode.Decoder ( Model, Cmd msg )
mutationDecoder _ =
    Json.Decode.oneOf
        []


{-| The decoder for the general API section.
This decoder is used to decode the subscription response of the general API section.

**Arguments**:

  - `model` - The model of the general API section.

**Returns**:

  - A decoder to update the general API section model.

-}
subscriptionDecoder : Model -> Json.Decode.Decoder ( Model, Cmd msg )
subscriptionDecoder model =
    Graphql.Document.decoder generalSubscription
        |> Json.Decode.map
            (\generalModel ->
                ( { model | time = Received generalModel.time }
                , Cmd.none
                )
            )
