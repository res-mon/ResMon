module LocalStorage exposing (GetCmdCallback, GetMsgCallback, Model, Msg, getCmd, getMsg, init, set, subscriptions, update)

import Dict exposing (Dict)
import Json.Encode exposing (Value)
import Platform.Cmd as Cmd
import PortFunnel.LocalStorage as LS exposing (Response(..))
import PortFunnels exposing (FunnelDict, Handler(..))
import Task



--  MODEL


type alias Model msg =
    { toMsg : Msg msg -> msg
    , funnel : PortFunnels.State
    , gets : Dict String (List (GetCmdCallback msg))
    }


init : (Msg msg -> msg) -> Model msg
init toMsg =
    { toMsg = toMsg
    , funnel = PortFunnels.initialState "resMon"
    , gets = Dict.empty
    }



-- UPDATE


type Msg msg
    = Process Value
    | ActionMsg (Action msg)


update : Msg msg -> Model msg -> Result String ( Model msg, Cmd msg )
update msg model =
    case msg of
        Process value ->
            process value model

        ActionMsg action ->
            case action of
                Get key callback cmd ->
                    let
                        add :
                            Dict comparable (List b)
                            -> comparable
                            -> b
                            -> Dict comparable (List b)
                        add dict k v =
                            case Dict.get k dict of
                                Just vs ->
                                    Dict.insert k (v :: vs) dict

                                Nothing ->
                                    Dict.insert k [ v ] dict
                    in
                    Ok
                        ( { model | gets = add model.gets key callback }
                        , cmd
                        )


process : Value -> Model msg -> Result String ( Model msg, Cmd msg )
process value model =
    PortFunnels.processValue funnelDict
        value
        model.funnel
        model



-- SUBSCRIPTIONS


subscriptions : Model msg -> Sub msg
subscriptions model =
    PortFunnels.subscriptions Process model
        |> Sub.map model.toMsg



-- API


type Action msg
    = Get String (GetCmdCallback msg) (Cmd msg)


type alias GetCmdCallback msg =
    Maybe Value -> Cmd msg


type alias GetMsgCallback msg =
    Maybe Value -> msg


set : Model msg -> String -> Maybe Value -> Cmd msg
set model key value =
    LS.send (getCmdPort Process LS.moduleName model)
        (LS.put key value)
        model.funnel.storage


getCmd : GetCmdCallback msg -> Model msg -> String -> Cmd msg
getCmd callback model key =
    Task.perform
        (\_ ->
            let
                cmd : Cmd msg
                cmd =
                    LS.send (getCmdPort Process LS.moduleName model)
                        (LS.get key)
                        model.funnel.storage
            in
            model.toMsg (ActionMsg (Get key callback cmd))
        )
        (Task.succeed ())


getMsg : GetMsgCallback msg -> Model msg -> String -> Cmd msg
getMsg callback =
    getCmd
        (\res ->
            Task.perform
                (\_ -> callback res)
                (Task.succeed ())
        )



-- FUNNEL


funnelDict : FunnelDict (Model msg) msg
funnelDict =
    PortFunnels.makeFunnelDict
        [ LocalStorageHandler storageHandler ]
        (getCmdPort Process)


storageHandler :
    LS.Response
    -> PortFunnels.State
    -> Model msg
    -> ( Model msg, Cmd msg )
storageHandler response state model =
    let
        ( gets, cmd ) =
            case response of
                GetResponse result ->
                    case Dict.get result.key model.gets of
                        Just callbacks ->
                            ( Dict.remove result.key model.gets
                            , List.map
                                (\callback -> callback result.value)
                                callbacks
                                |> Cmd.batch
                            )

                        _ ->
                            ( model.gets, Cmd.none )

                _ ->
                    ( model.gets, Cmd.none )
    in
    ( { model | funnel = state, gets = gets }, cmd )


getCmdPort : (Value -> Msg msg) -> String -> Model msg -> (Value -> Cmd msg)
getCmdPort tagger moduleName model =
    let
        res : Value -> Cmd (Msg msg)
        res =
            PortFunnels.getCmdPort tagger moduleName False
    in
    \value -> Cmd.map model.toMsg (res value)
