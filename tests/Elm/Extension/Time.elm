module Elm.Extension.Time exposing (all)

{-| This module contains tests for the `Extension.Time` mmodule.

@docs all

-}

import Expect
import Extension.Time exposing (fixVariationFloored, floorTo)
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
    describe "fixVariationFloored"
        [ fuzz posixFuzzer "without last time" <|
            \now ->
                let
                    interval : Int
                    interval =
                        1000
                in
                Expect.equal
                    (floorTo interval now)
                <|
                    fixVariationFloored now Nothing interval
        , test "test variation fix" <|
            \() ->
                let
                    expectations : List ( Int, Int, Int )
                    expectations =
                        [ ( 1172, 0, 1000 )
                        , ( 2537, 1172, 2000 )
                        , ( 3676, 2537, 3000 )
                        , ( 4755, 3676, 4000 )
                        , ( 5839, 4755, 5000 )
                        , ( 6347, 5839, 6000 )
                        , ( 7395, 6347, 7000 )
                        , ( 8783, 7395, 8000 )
                        , ( 9756, 8783, 9000 )
                        , ( 10664, 9756, 10000 )
                        , ( 11755, 10664, 11000 )
                        , ( 12723, 11755, 12000 )
                        , ( 13634, 12723, 13000 )
                        , ( 14882, 13634, 14000 )
                        , ( 15730, 14882, 15000 )
                        , ( 16627, 15730, 16000 )
                        ]

                    interval : Int
                    interval =
                        1000
                in
                Expect.all
                    (List.map
                        (\( now, last, expected ) () ->
                            Expect.equal
                                (Time.millisToPosix expected)
                            <|
                                fixVariationFloored
                                    (Time.millisToPosix now)
                                    (Just (Time.millisToPosix last))
                                    interval
                        )
                        expectations
                    )
                    ()
        ]
