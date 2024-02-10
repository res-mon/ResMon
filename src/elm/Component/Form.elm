module Component.Form exposing (InputElement, InputError, InputState, Model, Msg(..), defaultInputState, init, input, textInput, update)

import Css exposing (focus)
import Dict exposing (Dict)
import Html.Styled as Dom
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onBlur, onFocus, onInput)
import Maybe exposing (withDefault)
import Tailwind.Theme as Color
import Tailwind.Utilities as Tw



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
        -> List (Dom.Attribute msg)
        -> List (Dom.Html msg)
        -> Dom.Html msg
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
    -> List (Dom.Attribute msg)
    -> List (Dom.Html msg)
    -> Dom.Html msg
input inputType model id labelText onInputMsg currentValue errors attributes elements =
    let
        renderedErrors : Dom.Html msg
        renderedErrors =
            errors
                |> List.filter
                    (\err ->
                        showResolvableErrors
                            || not err.isResolveable
                    )
                |> List.map
                    (\err ->
                        Dom.li
                            [ Attr.css
                                [ Tw.text_color Color.rose_600
                                , Tw.mt_2
                                , Tw.mb_2
                                ]
                            ]
                            [ Dom.text err.value
                            ]
                    )
                |> Dom.ul []

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
    Dom.div []
        (Dom.label
            [ Attr.css
                [ Tw.block
                ]
            ]
            [ Dom.span
                [ Attr.css
                    [ Tw.text_color Color.gray_700
                    , Tw.font_semibold
                    ]
                ]
                [ Dom.text labelText ]
            , Dom.input
                (Attr.css
                    [ Tw.mt_0
                    , Tw.block
                    , Tw.w_full
                    , Tw.px_0_dot_5
                    , Tw.border_0
                    , Tw.border_b_2
                    , Tw.border_color Color.gray_200
                    , focus
                        [ Tw.ring_0
                        , Tw.border_color Color.black
                        ]
                    ]
                    :: Attr.type_ inputType
                    :: Attr.value currentValue
                    :: onFocus (model.toMsg (FocusChanged id True))
                    :: onBlur (model.toMsg (FocusChanged id False))
                    :: onInput onInputMsg
                    :: attributes
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
    -> List (Dom.Attribute msg)
    -> List (Dom.Html msg)
    -> Dom.Html msg
textInput =
    input "text"
