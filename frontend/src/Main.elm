module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
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
    , error : Maybe String
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        route =
            Route.fromUrl url

        ( homeModel, homeCmd ) =
            Pages.Home.init
    in
    ( { key = key
      , url = url
      , route = route
      , home = homeModel
      , error = Nothing
      }
    , Cmd.map HomeMsg homeCmd
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Pages.Home.Msg


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
            in
            ( { model | home = newHome, error = newHome.error }, Cmd.map HomeMsg cmd )


view : Model -> Browser.Document Msg
view model =
    let
        body =
            case model.route of
                Route.Home ->
                    [ Html.map HomeMsg (Pages.Home.view model.home) ]

                _ ->
                    [ text "404 - not found" ]

        -- to-do: add 404 page
        title =
            case model.route of
                Route.Home ->
                    "Saavu.fi"

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
    case error of
        Just err ->
            p [ style "color" "red" ] [ text err ]

        Nothing ->
            p [] []
