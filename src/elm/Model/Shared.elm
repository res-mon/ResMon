port module Model.Shared exposing
    ( Alert
    , AlertLevel(..)
    , Internal
    , Msg(..)
    , Route(..)
    , SharedModel
    , addTextAlert
    , init
    , removeAlert
    , setDarkModeMessage
    , subscriptions
    , update
    )

import Api
import Browser.Navigation exposing (Key, replaceUrl)
import Extension.Time exposing (fixVariationFloored)
import Html.Styled as Dom
import Json.Decode as D exposing (Value)
import Json.Encode
import LocalStorage as Ls
import Model.User exposing (User, decodeUser)
import Task
import Time exposing (Zone)
import Url exposing (Url, toString)



-- MODEL


currentUserKey : String
currentUserKey =
    "currentUser"


type Route
    = Loading
    | NotFound
    | WorkClock


type alias SharedModel msg =
    { route : Route
    , url : Url
    , key : Key
    , ls : Ls.Model msg
    , user : Maybe User
    , time : Maybe Time.Posix
    , timeZone : Maybe Zone
    , alerts : List (Alert msg)
    , internal : Internal msg
    , darkMode : Bool
    , api : Api.Model msg
    }


type Internal msg
    = Internal (InternalModel msg)


type alias InternalModel msg =
    { toMsg : Msg msg -> msg
    , updateRoute : msg
    , startUrl : Url
    , exactTime : Maybe Time.Posix
    , alertCount : Int
    }


type alias Alert msg =
    { number : Int
    , title : List (Dom.Html msg)
    , message : List (Dom.Html msg)
    , level : AlertLevel
    }


type AlertLevel
    = AlertNone
    | AlertInfo
    | AlertSuccess
    | AlertWarning
    | AlertError


init :
    (Msg msg -> msg)
    -> msg
    -> Route
    -> Url
    -> Key
    -> Ls.Model msg
    -> ( SharedModel msg, Cmd msg )
init toMsg updateRoute route url key localStorage =
    let
        ( apiModel, apiCmd ) =
            Api.init (ApiMsg >> toMsg)

        curentTimeCmd : Cmd msg
        curentTimeCmd =
            Time.now
                |> Task.perform
                    (\time -> toMsg (Tick time))

        lsCmd : Cmd msg
        lsCmd =
            Ls.getMsg (\res -> toMsg (UserLoaded res))
                model.ls
                currentUserKey

        model : SharedModel msg
        model =
            { route = route
            , url = url
            , key = key
            , ls = localStorage
            , user = Nothing
            , time = Nothing
            , timeZone = Nothing
            , alerts = []
            , internal =
                Internal
                    { toMsg = toMsg
                    , updateRoute = updateRoute
                    , startUrl = url
                    , exactTime = Nothing
                    , alertCount = 0
                    }
            , darkMode = False
            , api = apiModel
            }

        timeZoneCmd : Cmd msg
        timeZoneCmd =
            Task.perform
                (\zone -> toMsg (GotTimeZone zone))
                Time.here
    in
    ( model
    , Cmd.batch
        [ apiCmd
        , lsCmd
        , timeZoneCmd
        , curentTimeCmd
        ]
    )


unpackInternal : SharedModel msg -> InternalModel msg
unpackInternal model =
    let
        unpack : Internal msg -> InternalModel msg
        unpack (Internal internal) =
            internal
    in
    unpack model.internal


clockInterval : Int
clockInterval =
    1000



-- UPDATE


type Msg msg
    = UserLoaded (Maybe Value)
    | GotTimeZone Zone
    | Tick Time.Posix
    | DarkModeChanged Bool Bool
    | AlertAdded AlertLevel (List (Dom.Html msg)) (List (Dom.Html msg))
    | ApiMsg (Api.Msg msg)


update : Msg msg -> SharedModel msg -> ( SharedModel msg, Cmd msg )
update msg model =
    case msg of
        UserLoaded result ->
            case result of
                Just val ->
                    let
                        userResult : Result D.Error User
                        userResult =
                            D.decodeValue decodeUser val
                    in
                    case userResult of
                        Ok user ->
                            let
                                navigate : Cmd msg
                                navigate =
                                    replaceUrl model.key
                                        (toString (unpackInternal model).startUrl)

                                updateRoute : Cmd msg
                                updateRoute =
                                    Task.perform
                                        (\_ -> (unpackInternal model).updateRoute)
                                        (Task.succeed ())
                            in
                            ( { model | user = Just user }
                            , Cmd.batch [ updateRoute, navigate ]
                            )

                        Err err ->
                            ( addTextAlert
                                AlertError
                                model
                                "JSON-Deserialisation"
                                ("Konnte den Nutzer nicht deserialisieren: " ++ D.errorToString err)
                            , Cmd.none
                            )

                Nothing ->
                    ( model, Cmd.none )

        GotTimeZone zone ->
            ( { model | timeZone = Just zone }, Cmd.none )

        Tick time ->
            let
                flooredTime : Time.Posix
                flooredTime =
                    fixVariationFloored time internal.exactTime clockInterval

                internal : InternalModel msg
                internal =
                    unpackInternal model
            in
            ( { model
                | time = Just flooredTime
                , internal =
                    Internal
                        { internal
                            | exactTime = Just time
                        }
              }
            , Cmd.none
            )

        DarkModeChanged darkMode save ->
            ( { model | darkMode = darkMode }
            , if save then
                setDarkMode (Json.Encode.bool darkMode)

              else
                Cmd.none
            )

        AlertAdded level title message ->
            ( addAlert level model title message, Cmd.none )

        ApiMsg apiMsg ->
            let
                ( apiModel, apiCmd ) =
                    Api.update apiMsg model.api
            in
            ( { model | api = apiModel }, apiCmd )



-- API


addTextAlert :
    AlertLevel
    -> SharedModel msg
    -> String
    -> String
    -> SharedModel msg
addTextAlert level model title message =
    addAlert level
        model
        [ Dom.text title ]
        [ Dom.text message ]


addAlert :
    AlertLevel
    -> SharedModel msg
    -> List (Dom.Html msg)
    -> List (Dom.Html msg)
    -> SharedModel msg
addAlert level model title message =
    let
        internal : InternalModel msg
        internal =
            unpackInternal model

        number : Int
        number =
            internal.alertCount + 1
    in
    { model
        | alerts =
            { number = number, title = title, message = message, level = level }
                :: model.alerts
        , internal =
            Internal
                { internal
                    | alertCount = number
                }
    }


removeAlert : SharedModel msg -> Int -> SharedModel msg
removeAlert model number =
    { model
        | alerts =
            List.filter
                (\n -> n.number /= number)
                model.alerts
    }


setDarkModeMessage : SharedModel msg -> Bool -> msg
setDarkModeMessage model darkMode =
    (unpackInternal model).toMsg (DarkModeChanged darkMode True)



-- SUBSCRIPTION


subscriptions : SharedModel msg -> Sub msg
subscriptions model =
    Sub.batch
        [ Time.every (toFloat clockInterval) ((unpackInternal model).toMsg << Tick)
        , darkModeChanged
            (\value ->
                case D.decodeValue D.bool value of
                    Ok darkMode ->
                        (unpackInternal model).toMsg (DarkModeChanged darkMode False)

                    Err err ->
                        (unpackInternal model).toMsg
                            (AlertAdded AlertError
                                [ Dom.text "Unexpected value from dark mode changed port" ]
                                [ D.errorToString err |> Dom.text ]
                            )
            )
        , Api.subscriptions model.api
        ]



-- PORT


port darkModeChanged : (Value -> msg) -> Sub msg


port setDarkMode : Json.Encode.Value -> Cmd msg
