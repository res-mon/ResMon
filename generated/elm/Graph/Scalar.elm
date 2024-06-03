-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Graph.Scalar exposing (Any_(..), Codecs, FieldSet_(..), Id(..), Timestamp(..), defaultCodecs, defineCodecs, unwrapCodecs, unwrapEncoder)

import Graphql.Codec exposing (Codec)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Any_
    = Any_ String


type FieldSet_
    = FieldSet_ String


type Id
    = Id String


type Timestamp
    = Timestamp String


defineCodecs :
    { codecAny_ : Codec valueAny_
    , codecFieldSet_ : Codec valueFieldSet_
    , codecId : Codec valueId
    , codecTimestamp : Codec valueTimestamp
    }
    -> Codecs valueAny_ valueFieldSet_ valueId valueTimestamp
defineCodecs definitions =
    Codecs definitions


unwrapCodecs :
    Codecs valueAny_ valueFieldSet_ valueId valueTimestamp
    ->
        { codecAny_ : Codec valueAny_
        , codecFieldSet_ : Codec valueFieldSet_
        , codecId : Codec valueId
        , codecTimestamp : Codec valueTimestamp
        }
unwrapCodecs (Codecs unwrappedCodecs) =
    unwrappedCodecs


unwrapEncoder :
    (RawCodecs valueAny_ valueFieldSet_ valueId valueTimestamp -> Codec getterValue)
    -> Codecs valueAny_ valueFieldSet_ valueId valueTimestamp
    -> getterValue
    -> Graphql.Internal.Encode.Value
unwrapEncoder getter (Codecs unwrappedCodecs) =
    (unwrappedCodecs |> getter |> .encoder) >> Graphql.Internal.Encode.fromJson


type Codecs valueAny_ valueFieldSet_ valueId valueTimestamp
    = Codecs (RawCodecs valueAny_ valueFieldSet_ valueId valueTimestamp)


type alias RawCodecs valueAny_ valueFieldSet_ valueId valueTimestamp =
    { codecAny_ : Codec valueAny_
    , codecFieldSet_ : Codec valueFieldSet_
    , codecId : Codec valueId
    , codecTimestamp : Codec valueTimestamp
    }


defaultCodecs : RawCodecs Any_ FieldSet_ Id Timestamp
defaultCodecs =
    { codecAny_ =
        { encoder = \(Any_ raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Any_
        }
    , codecFieldSet_ =
        { encoder = \(FieldSet_ raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map FieldSet_
        }
    , codecId =
        { encoder = \(Id raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Id
        }
    , codecTimestamp =
        { encoder = \(Timestamp raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Timestamp
        }
    }