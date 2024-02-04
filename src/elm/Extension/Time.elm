module Extension.Time exposing (monthToInt, monthToString, toDateString)

import Time


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
