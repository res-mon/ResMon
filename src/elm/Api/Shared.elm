module Api.Shared exposing (State(..))

{-| This module contains the general types and functions that are used by all
APIs.

@docs State

-}


{-| The state of an API request.
It can be either `Unknown` or `Received` with a value.
-}
type State valueType
    = Unknown
    | Received valueType
