module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation exposing (Key)
import LocalStorage as Ls
import Model.Shared exposing (Route(..), SharedModel)
import Page.Layout as Layout
import Page.NotFound as NotFound
import Page.WorkClock as WorkClock
import Routing
import Url exposing (Url)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { shared : SharedModel Msg
    , layout : Layout.Model Msg
    , workClock : WorkClock.Model Msg
    }


init : () -> Url -> Key -> ( Model, Cmd Msg )
init () url key =
    let
        ( initialRoute, initialRouteCmd ) =
            Routing.init ()

        ( layoutModel, layoutCmd ) =
            Layout.init LayoutMsg shared

        model : Model
        model =
            { shared = shared
            , layout = layoutModel
            , workClock = workClockModel
            }

        ( route, routeCmd ) =
            Routing.update initialRoute url key

        ( shared, sharedCmd ) =
            Model.Shared.init SharedMsg
                UpdateRoute
                route
                url
                key
                (Ls.init LocalStorageMsg)

        ( workClockModel, workClockCmd ) =
            WorkClock.init WorkClockMsg shared
    in
    ( model
    , Cmd.batch
        [ sharedCmd
        , layoutCmd
        , routeCmd
        , initialRouteCmd
        , workClockCmd
        ]
    )



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked UrlRequest
    | UpdateRoute
    | SharedMsg (Model.Shared.Msg Msg)
    | LocalStorageMsg (Ls.Msg Msg)
    | LayoutMsg (Layout.Msg Msg)
    | WorkClockMsg (WorkClock.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( handleResultModel, handleResultCmd ) =
            case msg of
                UrlChanged url ->
                    let
                        ( route, routeCmd ) =
                            Routing.update shared.route shared.url shared.key

                        shared : SharedModel Msg
                        shared =
                            model.shared

                        updatedShared : SharedModel Msg
                        updatedShared =
                            { shared | route = route, url = url }
                    in
                    ( { model | shared = updatedShared }, routeCmd )

                LinkClicked request ->
                    case request of
                        Internal url ->
                            ( model
                            , Browser.Navigation.pushUrl
                                model.shared.key
                                (Url.toString url)
                            )

                        External url ->
                            ( model, Browser.Navigation.load url )

                UpdateRoute ->
                    let
                        ( route, routeCmd ) =
                            Routing.update shared.route shared.url shared.key

                        shared : SharedModel Msg
                        shared =
                            model.shared
                    in
                    ( { model | shared = { shared | route = route } }, routeCmd )

                SharedMsg inner ->
                    let
                        ( shared, cmd ) =
                            Model.Shared.update inner model.shared
                    in
                    ( { model | shared = shared }
                    , cmd
                    )

                LocalStorageMsg inner ->
                    let
                        currentShared : SharedModel Msg
                        currentShared =
                            model.shared

                        updateResult : Result String ( Ls.Model Msg, Cmd Msg )
                        updateResult =
                            Ls.update inner currentShared.ls
                    in
                    case updateResult of
                        Ok ( ls, cmd ) ->
                            ( { model | shared = { currentShared | ls = ls } }
                            , cmd
                            )

                        Err error ->
                            let
                                shared : SharedModel Msg
                                shared =
                                    Model.Shared.addTextAlert
                                        Model.Shared.AlertError
                                        currentShared
                                        "Port-Funnels"
                                        error
                            in
                            ( { model
                                | shared = shared
                              }
                            , Cmd.none
                            )

                LayoutMsg inner ->
                    let
                        ( shared, layout, cmd ) =
                            Layout.update inner model.shared model.layout
                    in
                    ( { model | shared = shared, layout = layout }
                    , cmd
                    )

                WorkClockMsg inner ->
                    let
                        ( shared, workClock, cmd ) =
                            WorkClock.update inner model.shared model.workClock
                    in
                    ( { model | shared = shared, workClock = workClock }
                    , cmd
                    )

        ( _, updateRoute ) =
            Routing.update model.shared.route model.shared.url model.shared.key
    in
    ( handleResultModel
    , Cmd.batch [ handleResultCmd, updateRoute ]
    )



-- VIEW


view : Model -> Document Msg
view model =
    let
        layout : Bool -> Document Msg -> Document Msg
        layout =
            Layout.view model.shared model.layout

        ( minimal, page ) =
            case model.shared.route of
                Loading ->
                    ( True, { title = "Loading", body = [] } )

                NotFound ->
                    ( model.shared.user == Nothing
                    , NotFound.view model.shared
                    )

                WorkClock ->
                    ( False
                    , WorkClock.view model.shared model.workClock
                    )
    in
    layout minimal page



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ls.subscriptions model.shared.ls
        , Model.Shared.subscriptions model.shared
        ]
