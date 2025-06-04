module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Pages.Admin
import Pages.CreateEvent
import Pages.Event
import Pages.Home
import Route
import Url


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route.Route
    , home : Pages.Home.Model
    , event : Pages.Event.Model
    , createEvent : Pages.CreateEvent.Model
    , admin : Pages.Admin.Model
    , error : Maybe String
    }


initFromUrl : Url.Url -> Route.Route -> Nav.Key -> ( Model, Cmd Msg )
initFromUrl url route key =
    let
        ( homeModel, homeCmd ) =
            case route of
                Route.Home ->
                    Pages.Home.init

                _ ->
                    ( Pages.Home.noop, Cmd.none )

        ( eventModel, eventCmd ) =
            case route of
                Route.Event id ->
                    Pages.Event.init id

                _ ->
                    ( Pages.Event.noop, Cmd.none )

        ( createModel, createCmd ) =
            case route of
                Route.CreateEvent ->
                    Pages.CreateEvent.init

                _ ->
                    ( Pages.CreateEvent.noop, Cmd.none )

        ( adminModel, adminCmd ) =
            case route of
                Route.Admin ->
                    Pages.Admin.init

                _ ->
                    ( Pages.Admin.noop, Cmd.none )
    in
    ( { key = key
      , url = url
      , route = route
      , home = homeModel
      , event = eventModel
      , createEvent = createModel
      , admin = adminModel
      , error = Nothing
      }
    , Cmd.batch
        [ Cmd.map HomeMsg homeCmd
        , Cmd.map EventMsg eventCmd
        , Cmd.map CreateEventMsg createCmd
        , Cmd.map AdminMsg adminCmd
        ]
    )


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        route =
            Route.fromUrl url
    in
    initFromUrl url route key


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Pages.Home.Msg
    | EventMsg Pages.Event.Msg
    | CreateEventMsg Pages.CreateEvent.Msg
    | AdminMsg Pages.Admin.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                route =
                    Route.fromUrl url

                ( newModel, newCmd ) =
                    initFromUrl url route model.key
            in
            ( newModel, newCmd )

        HomeMsg subMsg ->
            let
                ( newHome, cmd ) =
                    Pages.Home.update subMsg model.home

                newError =
                    case newHome.error of
                        Just err ->
                            Just err

                        Nothing ->
                            model.error
            in
            ( { model | home = newHome, error = newError }, Cmd.map HomeMsg cmd )

        EventMsg subMsg ->
            let
                ( newEvent, cmd ) =
                    Pages.Event.update subMsg model.event

                newError =
                    case newEvent.error of
                        Just err ->
                            Just err

                        Nothing ->
                            model.error
            in
            ( { model | event = newEvent, error = newError }, Cmd.map EventMsg cmd )

        CreateEventMsg subMsg ->
            let
                ( newCreateEvent, cmd ) =
                    Pages.CreateEvent.update subMsg model.createEvent

                newError =
                    case newCreateEvent.error of
                        Just err ->
                            Just err

                        Nothing ->
                            model.error
            in
            ( { model | createEvent = newCreateEvent, error = newError }, Cmd.map CreateEventMsg cmd )

        AdminMsg subMsg ->
            let
                ( newAdmin, cmd ) =
                    Pages.Admin.update subMsg model.admin

                newError =
                    case newAdmin.error of
                        Just err ->
                            Just err

                        Nothing ->
                            model.error
            in
            ( { model | admin = newAdmin, error = newError }, Cmd.map AdminMsg cmd )


view : Model -> Browser.Document Msg
view model =
    let
        body =
            case model.route of
                Route.Home ->
                    [ Html.map HomeMsg (Pages.Home.view model.home) ]

                Route.Event id ->
                    [ Html.map EventMsg (Pages.Event.view model.event) ]

                Route.CreateEvent ->
                    [ Html.map CreateEventMsg (Pages.CreateEvent.view model.createEvent) ]

                Route.Admin ->
                    [ Html.map AdminMsg (Pages.Admin.view model.admin) ]

                _ ->
                    [ text "404 - not found" ]

        -- to-do: add 404 page
        title =
            case model.route of
                Route.Home ->
                    "Saavu.fi"

                Route.Event id ->
                    "Saavu.fi - " ++ id

                Route.CreateEvent ->
                    "Saavu.fi - Create event"

                Route.Admin ->
                    "Saavu.fi - Admin"

                _ ->
                    "Saavu.fi"
    in
    { title = title
    , body =
        div [ class "App" ]
            [ div [ class "Status" ]
                [ p [] [ text ("url: " ++ Url.toString model.url) ]
                , viewErrorDialog model.error
                , h1 [] [ text title ]
                ]
            ]
            :: body
    }


viewErrorDialog : Maybe String -> Html Msg
viewErrorDialog error =
    let
        _ =
            Debug.log "error" error
    in
    case error of
        Just err ->
            p [ style "color" "red" ] [ text err ]

        Nothing ->
            p [] []
