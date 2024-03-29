-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Graph.Object.ActivityQuery exposing (..)

import Api.ScalarCodecs
import Graph.InputObject
import Graph.Interface
import Graph.Object
import Graph.Scalar
import Graph.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


{-| The timestamp since the activity state was last changed.
Returns the timestamp since the activity state was last changed.
-}
since : SelectionSet Api.ScalarCodecs.Timestamp Graph.Object.ActivityQuery
since =
    Object.selectionForField "Api.ScalarCodecs.Timestamp" "since" [] (Api.ScalarCodecs.codecs |> Graph.Scalar.unwrapCodecs |> .codecTimestamp |> .decoder)


{-| This indicates if the user is currently working or not.
Returns the current activity state.
-}
active : SelectionSet Bool Graph.Object.ActivityQuery
active =
    Object.selectionForField "Bool" "active" [] Decode.bool
