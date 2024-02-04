module Component.Form exposing (InputElement, InputError, InputState, Model, Msg(..), defaultInputState, init, input, textInput, update)

import Css exposing (focus)
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, label, li, span, text, ul)
import Html.Styled.Attributes exposing (css, type_, value)
import Html.Styled.Events exposing (onBlur, onFocus, onInput)
import Maybe exposing (withDefault)
import Tailwind.Theme exposing (black, gray_200, gray_700, rose_600)
import Tailwind.Utilities exposing (block, border_0, border_b_2, border_color, font_semibold, mb_2, mt_0, mt_2, px_0_dot_5, ring_0, text_color, w_full)



-- MODEL


type alias Model msg =
    { toMsg : Msg msg -> msg
    , inputStates : Dict String InputState
    }


type alias InputError =
    { value : String
    , isResolveable : Bool
    }


type alias InputState =
    { hasFocus : Bool
    }


defaultInputState : Maybe InputState -> InputState
defaultInputState state =
    withDefault
        { hasFocus = False }
        state


type alias InputElement msg =
    { id : String
    , wasFocused : Bool
    , hasFocus : Bool
    , render :
        String
        -> List InputError
        -> List (Html.Styled.Attribute msg)
        -> List (Html msg)
        -> Html msg
    }


init : (Msg msg -> msg) -> Model msg
init toMsg =
    { toMsg = toMsg, inputStates = Dict.empty }



-- UPDATE


type Msg msg
    = FocusChanged String Bool


update : Msg msg -> Model msg -> Model msg
update msg model =
    let
        updateInput : String -> (InputState -> InputState) -> Model msg
        updateInput id inputUpdate =
            { model
                | inputStates =
                    updateInputStates
                        id
                        inputUpdate
                        model.inputStates
            }

        updateInputStates :
            String
            -> (InputState -> InputState)
            -> Dict String InputState
            -> Dict String InputState
        updateInputStates id inputUpdate dict =
            Dict.update id
                (\m ->
                    defaultInputState m
                        |> inputUpdate
                        |> Just
                )
                dict
    in
    case msg of
        FocusChanged id hasFocus ->
            updateInput id (\i -> { i | hasFocus = hasFocus })



-- VIEW


input :
    String
    -> Model msg
    -> String
    -> String
    -> (String -> msg)
    -> String
    -> List InputError
    -> List (Html.Styled.Attribute msg)
    -> List (Html msg)
    -> Html msg
input inputType model id labelText onInputMsg currentValue errors attributes elements =
    let
        renderedErrors : Html msg
        renderedErrors =
            errors
                |> List.filter
                    (\err ->
                        showResolvableErrors
                            || not err.isResolveable
                    )
                |> List.map
                    (\err ->
                        li
                            [ css
                                [ text_color rose_600
                                , mt_2
                                , mb_2
                                ]
                            ]
                            [ text err.value
                            ]
                    )
                |> ul []

        showResolvableErrors : Bool
        showResolvableErrors =
            case state of
                Just s ->
                    not s.hasFocus

                Nothing ->
                    False

        state : Maybe InputState
        state =
            Dict.get id model.inputStates
    in
    div []
        (label
            [ css
                [ block
                ]
            ]
            [ span
                [ css
                    [ text_color gray_700
                    , font_semibold
                    ]
                ]
                [ text labelText ]
            , Html.Styled.input
                ([ css
                    [ mt_0
                    , block
                    , w_full
                    , px_0_dot_5
                    , border_0
                    , border_b_2
                    , border_color gray_200
                    , focus
                        [ ring_0
                        , border_color black
                        ]
                    ]
                 , type_ inputType
                 , value currentValue
                 , onFocus (model.toMsg (FocusChanged id True))
                 , onBlur (model.toMsg (FocusChanged id False))
                 , onInput onInputMsg
                 ]
                    ++ attributes
                )
                []
            , renderedErrors
            ]
            :: elements
        )


textInput :
    Model msg
    -> String
    -> String
    -> (String -> msg)
    -> String
    -> List InputError
    -> List (Html.Styled.Attribute msg)
    -> List (Html msg)
    -> Html msg
textInput =
    input "text"
