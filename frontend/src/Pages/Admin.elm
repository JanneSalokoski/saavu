module Pages.Home exposing (..)

import Browser
import Browser.Navigation as Nav
import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D
import Json.Encode as E
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
    { eventNameInput : String
    , events : List Event.Event
    , featureNameInput : String
    , featureDescriptionInput : String
    , features : List Feature.Feature
    , error : Maybe String
    , key : Nav.Key
    , url : Url.Url
    , route : Route.Route
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { eventNameInput = ""
      , featureNameInput = ""
      , featureDescriptionInput = ""
      , events = []
      , features = []
      , error = Nothing
      , key = key
      , url = url
      , route = Route.fromUrl url
      }
    , Cmd.batch
        [ fetchEvents
        , fetchFeatures
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Msg
    = UpdateEventName String
    | UpdateFeatureName String
    | UpdateFeatureDescription String
    | SubmitEvent
    | SubmitFeature
    | EventsFetched (Result Http.Error (List Event.Event))
    | EventCreated (Result Http.Error Event.Event)
    | FeaturesFetched (Result Http.Error (List Feature.Feature))
    | FeatureCreated (Result Http.Error Feature.Feature)
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateEventName str ->
            ( { model | eventNameInput = str }, Cmd.none )

        UpdateFeatureName str ->
            ( { model | featureNameInput = str }, Cmd.none )

        UpdateFeatureDescription str ->
            ( { model | featureDescriptionInput = str }, Cmd.none )

        SubmitEvent ->
            let
                body =
                    Http.jsonBody <| Event.eventEncoder { id = "", name = model.eventNameInput }
            in
            ( model
            , Http.post
                { url = "/api/events/"
                , body = body
                , expect = Http.expectJson EventCreated Event.eventDecoder
                }
            )

        SubmitFeature ->
            let
                body =
                    Http.jsonBody <| Feature.featureEncoder { id = "", name = model.featureNameInput, description = model.featureDescriptionInput }
            in
            ( model
            , Http.post
                { url = "/api/features/"
                , body = body
                , expect = Http.expectJson FeatureCreated Feature.featureDecoder
                }
            )

        EventCreated (Ok event) ->
            ( { model | events = event :: model.events, eventNameInput = "" }, Cmd.none )

        EventCreated (Err e) ->
            ( { model | error = Just ("Create failed: " ++ Debug.toString e) }, Cmd.none )

        EventsFetched (Ok evs) ->
            ( { model | events = evs }, Cmd.none )

        EventsFetched (Err e) ->
            ( { model | error = Just ("Fetch failed: " ++ Debug.toString e) }, Cmd.none )

        FeatureCreated (Ok feature) ->
            ( { model | features = feature :: model.features, featureNameInput = "" }, Cmd.none )

        FeatureCreated (Err e) ->
            ( { model | error = Just ("Create failed: " ++ Debug.toString e) }, Cmd.none )

        FeaturesFetched (Ok features) ->
            ( { model | features = features }, Cmd.none )

        FeaturesFetched (Err e) ->
            ( { model | error = Just ("Fetch failed: " ++ Debug.toString e) }, Cmd.none )

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


fetchEvents : Cmd Msg
fetchEvents =
    Http.get
        { url = "/api/events/"
        , expect = Http.expectJson EventsFetched (Decode.list Event.eventDecoder)
        }


fetchFeatures : Cmd Msg
fetchFeatures =
    Http.get
        { url = "/api/features/"
        , expect = Http.expectJson FeaturesFetched (Decode.list Feature.featureDecoder)
        }


view : Model -> Browser.Document Msg
view model =
    let
        _ =
            Debug.log "route" model.route
    in
    { title = "Saavu.fi"
    , body =
        [ div []
            [ p [] [ text (Url.toString model.url) ]
            , viewEvents model.events
            , viewCreateEvent model.eventNameInput
            , viewFeatures model.features
            , viewCreateFeature model.featureNameInput model.featureDescriptionInput
            , viewErrorDialog model.error
            ]
        ]
    }


viewEvents : List Event.Event -> Html Msg
viewEvents events =
    div [ class "events" ]
        [ h2 [] [ text "Events" ]
        , ul [] (List.map viewEvent (List.sortBy .name events))
        ]


viewEvent : Event.Event -> Html Msg
viewEvent event =
    li [] [ text ("[" ++ event.id ++ "] " ++ event.name) ]


viewCreateEvent : String -> Html Msg
viewCreateEvent eventName =
    div []
        [ input [ placeholder "Event name", value eventName, onInput UpdateEventName ] []
        , button [ onClick SubmitEvent ] [ text "Create an event" ]
        ]


viewFeatures : List Feature.Feature -> Html Msg
viewFeatures features =
    div [ class "features" ]
        [ h2 [] [ text "Features" ]
        , ul [] (List.map viewFeature (List.sortBy .name features))
        ]


viewFeature : Feature.Feature -> Html Msg
viewFeature feature =
    li []
        [ div []
            [ p [] [ text feature.name ]
            , p [] [ text feature.description ]
            ]
        ]


viewCreateFeature : String -> String -> Html Msg
viewCreateFeature featureName featureDescription =
    div [ class "feature", class "create" ]
        [ input [ placeholder "Feature name", value featureName, onInput UpdateFeatureName ] []
        , textarea [ placeholder "Description", value featureDescription, onInput UpdateFeatureDescription ] []
        , button [ onClick SubmitFeature ] [ text "Create a feature" ]
        ]


viewErrorDialog : Maybe String -> Html Msg
viewErrorDialog error =
    case error of
        Just err ->
            div [ style "color" "red" ] [ text err ]

        Nothing ->
            text ""
