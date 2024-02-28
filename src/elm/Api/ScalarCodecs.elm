module Api.ScalarCodecs exposing (Any_, FieldSet_, Id(..), Timestamp, codecs)

{-| This module contains the scalar types and their codecs for the GraphQL schema.

@docs Any_, FieldSet_, Id, Timestamp, codecs

-}

import Graph.Scalar exposing (defaultCodecs)
import Json.Decode as Decode
import Json.Encode as Encode
import Time


{-| Represents a `any` scalar type in the GraphQL schema.
-}
type alias Any_ =
    Graph.Scalar.Any_


{-| Represents a `fieldSet` scalar type in the GraphQL schema.
-}
type alias FieldSet_ =
    Graph.Scalar.FieldSet_


{-| Represents a `id` scalar type in the GraphQL schema.
The inner type of `Id` is an `Int`.
-}
type Id
    = Id Int


{-| Represents a `timestamp` scalar type in the GraphQL schema.
The inner type of `Timestamp` is a `Time.Posix`.
-}
type alias Timestamp =
    Time.Posix


{-| The codecs for the scalar types in the GraphQL schema.
This is used to encode and decode values of the scalar types.
-}
codecs : Graph.Scalar.Codecs Any_ FieldSet_ Id Timestamp
codecs =
    Graph.Scalar.defineCodecs
        { codecAny_ = defaultCodecs.codecAny_
        , codecFieldSet_ = defaultCodecs.codecFieldSet_
        , codecId =
            { encoder = \(Id raw) -> raw |> String.fromInt |> Encode.string
            , decoder =
                Decode.string
                    |> Decode.map String.toInt
                    |> Decode.andThen
                        (\maybeParsedId ->
                            case maybeParsedId of
                                Just parsedId ->
                                    Decode.succeed parsedId

                                Nothing ->
                                    Decode.fail "Could not parse ID as an Int."
                        )
                    |> Decode.map Id
            }
        , codecTimestamp =
            { encoder = Time.posixToMillis >> Encode.int
            , decoder = Decode.int |> Decode.map Time.millisToPosix
            }
        }
