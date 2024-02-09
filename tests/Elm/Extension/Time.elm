module Elm.Extension.Time exposing (all)

{-| This module contains tests for the `Extension.Time` mmodule.

@docs all

-}

import Expect
import Extension.Time exposing (fixVariation, floorTo)
import Fuzz
import Test exposing (Test, describe, fuzz, test)
import Time



-- FUZZER


posixFuzzer : Fuzz.Fuzzer Time.Posix
posixFuzzer =
    Fuzz.map Time.millisToPosix (Fuzz.intRange 0 100000)



-- TEST


{-| Tests all exposed functions in the `Extension.Time` module.
-}
all : Test
all =
    describe "Expansion.Time Tests"
        [ fixVariationTests
        ]


fixVariationTests : Test
fixVariationTests =
    describe "fixVariation"
        [ fuzz posixFuzzer "without last time" <|
            \now ->
                let
                    interval : Int
                    interval =
                        5000
                in
                Expect.equal
                    now
                <|
                    fixVariation now Nothing interval
        , test "test variation fix" <|
            \() ->
                let
                    expectations : List ( Int, Int, Int )
                    expectations =
                        [ ( 100000, 100000, 100000 )
                        , ( 105000, 100000, 105000 )
                        , ( 110000, 105000, 110000 )
                        , ( 114999, 110000, 115000 )
                        , ( 120000, 114999, 120000 )
                        , ( 125000, 120000, 125000 )
                        , ( 129999, 125000, 130000 )
                        , ( 135000, 129999, 135000 )
                        ]

                    interval : Int
                    interval =
                        5000
                in
                Expect.all
                    (List.map
                        (\( now, last, expected ) () ->
                            Expect.equal
                                (Time.millisToPosix expected)
                            <|
                                floorTo
                                    interval
                                    (fixVariation
                                        (Time.millisToPosix now)
                                        (Just (Time.millisToPosix last))
                                        interval
                                    )
                        )
                        expectations
                    )
                    ()
        ]
