module Model.Shared exposing (Alert, AlertLevel(..), Internal, Msg(..), Route(..), SharedModel, addTextAlert, init, removeAlert, subscriptions, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation exposing (Key, replaceUrl)
import Extension.Time exposing (fixVariation, floorTo)
import Html.Styled exposing (Html, text)
import Json.Decode as D exposing (Value)
import LocalStorage as LS
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
    , ls : LS.Model msg
    , user : Maybe User
    , time : Maybe Time.Posix
    , timeZone : Maybe Zone
    , alerts : List (Alert msg)
    , internal : Internal msg
    }


type alias Internal msg =
    { toMsg : Msg msg -> msg
    , updateRoute : msg
    , startUrl : Url
    , exactTime : Maybe Time.Posix
    , alertCount : Int
    }


type alias Alert msg =
    { number : Int
    , title : List (Html msg)
    , message : List (Html msg)
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
    -> LS.Model msg
    -> ( SharedModel msg, Cmd msg )
init toMsg updateRoute route url key localStorage =
    let
        lsCmd : Cmd msg
        lsCmd =
            LS.getMsg (\res -> toMsg (UserLoaded res))
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
                { toMsg = toMsg
                , updateRoute = updateRoute
                , startUrl = url
                , exactTime = Nothing
                , alertCount = 0
                }
            }

        timeZoneCmd : Cmd msg
        timeZoneCmd =
            Task.perform
                (\zone -> toMsg (GotTimeZone zone))
                Time.here

        curentTimeCmd : Cmd msg
        curentTimeCmd =
            Time.now
                |> Task.perform
                    (\time -> toMsg (Tick time))
    in
    ( model, Cmd.batch [ lsCmd, timeZoneCmd, curentTimeCmd ] )


clockInterval : Int
clockInterval =
    5000



-- UPDATE


type Msg msg
    = UserLoaded (Maybe Value)
    | GotTimeZone Zone
    | Tick Time.Posix


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
                                        (toString model.internal.startUrl)

                                updateRoute : Cmd msg
                                updateRoute =
                                    Task.perform
                                        (always model.internal.updateRoute)
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
                floorTime : Time.Posix
                floorTime =
                    fixVariation time model.internal.exactTime clockInterval

                flooredTime : Time.Posix
                flooredTime =
                    floorTo clockInterval floorTime

                internal : Internal msg
                internal =
                    model.internal
            in
            ( { model
                | time = Just flooredTime
                , internal =
                    { internal
                        | exactTime = Just time
                    }
              }
            , Cmd.none
            )



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
        [ text title ]
        [ text message ]


addAlert :
    AlertLevel
    -> SharedModel msg
    -> List (Html msg)
    -> List (Html msg)
    -> SharedModel msg
addAlert level model title message =
    let
        internal : Internal msg
        internal =
            model.internal

        number : Int
        number =
            internal.alertCount + 1
    in
    { model
        | alerts =
            { number = number, title = title, message = message, level = level }
                :: model.alerts
        , internal =
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



-- SUBSCRIPTIONS


subscriptions : SharedModel msg -> Sub msg
subscriptions model =
    Time.every (toFloat clockInterval) (model.internal.toMsg << Tick)
