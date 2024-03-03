module Component.Time exposing (clock)

{-| Contains components for rendering time, date and related information.

@docs clock

-}

import Component.DaisyUi as Ui
import Html.Styled as Dom exposing (Html)
import Tailwind.Utilities as Tw
import Time exposing (Posix, Zone)


{-| Renders a time as a clock in the followind format: HH:mm:ss.

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
