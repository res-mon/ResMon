-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Graph.Object.ActivityMutation exposing (..)

import Graph.InputObject
import Graph.Interface
import Graph.Object
import Graph.Scalar
import Graph.ScalarCodecs
import Graph.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


type alias SetActiveRequiredArguments =
    { active : Bool }


{-| Sets the current activity state.
This indicates if the user is currently working or not.
Returns the new activity state.
-}
setActive :
    SetActiveRequiredArguments
    -> SelectionSet Bool Graph.Object.ActivityMutation
setActive requiredArgs____ =
    Object.selectionForField "Bool" "setActive" [ Argument.required "active" requiredArgs____.active Encode.bool ] Decode.bool
