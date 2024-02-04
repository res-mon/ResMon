module Routing exposing (init, update)

import Browser.Navigation exposing (Key, replaceUrl)
import Extension.Url exposing (routeParts)
import Model.Shared exposing (Route(..))
import Url exposing (Url)



-- MODEL


init : () -> ( Route, Cmd msg )
init () =
    ( Loading, Cmd.none )



-- UPDATE


update : Route -> Url -> Key -> ( Route, Cmd msg )
update route url key =
    let
        parts : List String
        parts =
            routeParts url
    in
    case parts of
        [] ->
            ( route, replaceUrl key "/WorkClock" )

        [ "workclock" ] ->
            ( WorkClock, Cmd.none )

        _ ->
            ( NotFound, Cmd.none )
