module Extension.Time exposing (fixVariationFloored, floorTo, groupBy, monthToInt, monthToString, roundTo, toDateString)

{-| This module provides utility functions for working with Time.

@docs fixVariationFloored, floorTo, groupBy, monthToInt, monthToString, roundTo, toDateString

-}

import Basics.Extra exposing (safeDivide)
import Time


{-| Converts a given time to a date string.
-}
toDateString : Time.Zone -> Time.Posix -> String
toDateString zone posix =
    let
        day : Int
        day =
            Time.toDay zone posix

        month : Int
        month =
            Time.toMonth zone posix
                |> monthToInt

        year : Int
        year =
            Time.toYear zone posix
    in
    String.concat
        [ String.padLeft 2 '0' (String.fromInt day)
        , "."
        , String.padLeft 2 '0' (String.fromInt month)
        , "."
        , String.fromInt year
        ]


{-| Converts a month to an integer.
-}
monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


{-| Converts a month to a string.
-}
monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "Januar"

        Time.Feb ->
            "Februar"

        Time.Mar ->
            "März"

        Time.Apr ->
            "April"

        Time.May ->
            "Mai"

        Time.Jun ->
            "Juni"

        Time.Jul ->
            "Juli"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "Oktober"

        Time.Nov ->
            "November"

        Time.Dec ->
            "Dezember"


{-| Adjusts the time by a given variation.
-}
fixVariationFloored : Time.Posix -> Maybe Time.Posix -> Int -> Time.Posix
fixVariationFloored now lastTime interval =
    if interval == 0 then
        floorTo interval now

    else
        case lastTime of
            Just last ->
                let
                    currentMillis : Int
                    currentMillis =
                        Time.posixToMillis now

                    delta : Int
                    delta =
                        currentMillis - lastMillis

                    intervals : Int
                    intervals =
                        safeDivide (toFloat delta)
                            (toFloat interval)
                            |> Maybe.withDefault 0
                            |> round

                    lastMillis : Int
                    lastMillis =
                        Time.posixToMillis last

                    millis : Int
                    millis =
                        if intervals == 0 then
                            currentMillis + (interval // 2)

                        else
                            lastMillis + interval * intervals
                in
                Time.millisToPosix millis
                    |> floorTo interval

            Nothing ->
                floorTo interval now


{-| Groups a list of times by a given unit.
-}
groupBy : (Float -> Int) -> Int -> Time.Posix -> Time.Posix
groupBy grouping intervalMillis posix =
    let
        millis : Float
        millis =
            Time.posixToMillis posix
                |> toFloat

        roundedMillis : Int
        roundedMillis =
            safeDivide millis (toFloat intervalMillis)
                |> Maybe.withDefault 0
                |> grouping
                |> (*) intervalMillis
    in
    Time.millisToPosix roundedMillis


{-| Rounds a given time to the nearest unit.
-}
roundTo : Int -> Time.Posix -> Time.Posix
roundTo intervalMillis posix =
    groupBy round intervalMillis posix


{-| Rounds down a given time to the nearest unit.
-}
floorTo : Int -> Time.Posix -> Time.Posix
floorTo intervalMillis posix =
    groupBy floor intervalMillis posix
