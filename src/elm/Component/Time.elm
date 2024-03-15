module Component.Time exposing (clock, date, deltaClock, durationClock)

{-| Contains components for rendering time, date and related information.

@docs clock, date, deltaClock, durationClock

-}

import Component.DaisyUi as Ui
import Extension.Time exposing (monthToInt)
import Html.Styled as Dom exposing (Html)
import Tailwind.Utilities as Tw
import Time exposing (Posix, Zone)


{-| Renders a time as a clock in the followind format: `HH:mm:ss`.

**Arguments**:

  - `zone` - The time zone to use for the clock. If `Nothing`, `00:00:00` will be returned.
  - `posix` - The time to display. If `Nothing`, `00:00:00` will be returned.

**Returns**:

  - A list of `Html` elements representing the clock.

-}
clock : Maybe Zone -> Maybe Posix -> List (Html msg)
clock zone posix =
    let
        hour : Int
        hour =
            mapTime Time.toHour zone posix

        mapTime :
            (Zone -> Posix -> Int)
            -> Maybe Zone
            -> Maybe Posix
            -> Int
        mapTime f z p =
            Maybe.map2 f z p
                |> Maybe.withDefault 0

        minute : Int
        minute =
            mapTime Time.toMinute zone posix

        number : Int -> Html msg
        number value =
            Ui.countdown []
                [ Tw.duration_500 ]
                value

        second : Int
        second =
            mapTime Time.toSecond zone posix
    in
    [ number hour
    , Dom.text ":"
    , number minute
    , Dom.text ":"
    , number second
    ]


{-| Renders a time as a date in the followind format: `dd.MM.yyyy`.

**Arguments**:

  - `zone` - The time zone to use for the date. If `Nothing`, `00.00.0000` will be returned.
  - `posix` - The date to display. If `Nothing`, `00.00.0000` will be returned.

**Returns**:

  - A list of `Html` elements representing the date.

-}
date : Maybe Zone -> Maybe Posix -> List (Html msg)
date zone posix =
    let
        day : Int
        day =
            mapTime Time.toDay zone posix

        mapTime :
            (Zone -> Posix -> Int)
            -> Maybe Zone
            -> Maybe Posix
            -> Int
        mapTime f z p =
            Maybe.map2 f z p
                |> Maybe.withDefault 0

        month : Int
        month =
            mapTime (\z p -> Time.toMonth z p |> monthToInt) zone posix

        number : Int -> Html msg
        number value =
            Ui.countdown []
                [ Tw.duration_500 ]
                value

        year : Int
        year =
            mapTime Time.toYear zone posix
    in
    [ number day
    , Dom.text "."
    , number month
    , Dom.text "."
    , number (year // 100)
    , number (modBy 100 year)
    ]


{-| Renders the delta between two times as a clock in the followind format: `HH:mm:ss`.

**Arguments**:

  - `previous` - The prevoius time. If `Nothing`, `00:00:00` will be returned.
  - `current` - The current time. If `Nothing`, `00:00:00` will be returned.

**Returns**:

  - A list of `Html` elements representing the clock.

-}
deltaClock : Maybe Posix -> Maybe Posix -> List (Html msg)
deltaClock previous current =
    durationClock
        (Maybe.withDefault 0
            (Maybe.map2
                (\p c -> Time.posixToMillis c - Time.posixToMillis p)
                previous
                current
            )
        )


{-| Renders the duration as a clock in the followind format: `HH:mm:ss`.

**Arguments**:

  - `durationMillis` - The pduration in milliseconds. If negative, `00:00:00` will be returned.

**Returns**:

  - A list of `Html` elements representing the clock.

-}
durationClock : Int -> List (Html msg)
durationClock durationMillis =
    let
        duration : Int
        duration =
            (durationMillis |> toFloat)
                / 1000
                |> round
                |> max 0

        hours : Int
        hours =
            duration // 3600

        minutes : Int
        minutes =
            modBy 60 (duration // 60)

        number : Int -> Html msg
        number value =
            Ui.countdown []
                [ Tw.duration_500 ]
                value

        seconds : Int
        seconds =
            modBy 60 duration
    in
    [ number hours
    , Dom.text ":"
    , number minutes
    , Dom.text ":"
    , number seconds
    ]
