-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Graph.VerifyScalarCodecs exposing (..)

{-
   This file is intended to be used to ensure that custom scalar decoder
   files are valid. It is compiled using `elm make` by the CLI.
-}

import Api.ScalarCodecs
import Graph.Scalar


verify : Graph.Scalar.Codecs Api.ScalarCodecs.Any_ Api.ScalarCodecs.FieldSet_ Api.ScalarCodecs.Id Api.ScalarCodecs.Timestamp
verify =
    Api.ScalarCodecs.codecs
