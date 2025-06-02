module Pages.Home exposing (Model, Msg, init, update, view)

import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D


type alias Model =
    { eventNameInput : String
    , events : List Event.Event
    , featureNameInput : String
    , featureDescriptionInput : String
    , features : List Feature.Feature
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    ( { eventNameInput = ""
      , featureNameInput = ""
      , featureDescriptionInput = ""
      , events = []
      , features = []
      , error = Nothing
      }
    , Cmd.batch
        [ fetchEvents
        , fetchFeatures
        ]
    )


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
                { url = "/api/events"
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
                { url = "/api/features"
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


fetchEvents : Cmd Msg
fetchEvents =
    Http.get
        { url = "/api/events"
        , expect = Http.expectJson EventsFetched (D.list Event.eventDecoder)
        }


fetchFeatures : Cmd Msg
fetchFeatures =
    Http.get
        { url = "/api/features"
        , expect = Http.expectJson FeaturesFetched (D.list Feature.featureDecoder)
        }


view : Model -> Html Msg
view model =
    div []
        [ viewEvents model.events
        , viewCreateEvent model.eventNameInput
        , viewFeatures model.features
        , viewCreateFeature model.featureNameInput model.featureDescriptionInput
        ]


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
