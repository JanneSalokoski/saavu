module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
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
    , error : Maybe String
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        route =
            Route.fromUrl url

        ( homeModel, homeCmd ) =
            Pages.Home.init

        ( eventModel, eventCmd ) =
            case route of
                Route.Event id ->
                    Pages.Event.init id

                _ ->
                    Pages.Event.init ""
    in
    ( { key = key
      , url = url
      , route = route
      , home = homeModel
      , event = eventModel
      , error = Nothing
      }
    , Cmd.batch
        [ Cmd.map HomeMsg homeCmd
        , Cmd.map EventMsg eventCmd
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Pages.Home.Msg
    | EventMsg Pages.Event.Msg


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
            ( { model | url = url }
            , Cmd.none
            )

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


view : Model -> Browser.Document Msg
view model =
    let
        body =
            case model.route of
                Route.Home ->
                    [ Html.map HomeMsg (Pages.Home.view model.home) ]

                Route.Event id ->
                    [ Html.map EventMsg (Pages.Event.view model.event) ]

                _ ->
                    [ text "404 - not found" ]

        -- to-do: add 404 page
        title =
            case model.route of
                Route.Home ->
                    "Saavu.fi"

                Route.Admin ->
                    "Saavu.fi - Admin"

                Route.Event id ->
                    "Saavu.fi - " ++ id

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
    case error of
        Just err ->
            p [ style "color" "red" ] [ text err ]

        Nothing ->
            p [] []
