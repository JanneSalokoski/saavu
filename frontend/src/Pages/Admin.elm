module Pages.Admin exposing (Model, Msg, init, noop, update, view)

import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D


type alias Model =
    { events : List Event.Event
    , featureNameInput : String
    , featureDescriptionInput : String
    , features : List Feature.Feature
    , error : Maybe String
    }


noop : Model
noop =
    { events = []
    , featureNameInput = ""
    , featureDescriptionInput = ""
    , features = []
    , error = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( { featureNameInput = ""
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
    = UpdateFeatureName String
    | UpdateFeatureDescription String
    | SubmitFeature
    | EventsFetched (Result Http.Error (List Event.Event))
    | FeaturesFetched (Result Http.Error (List Feature.Feature))
    | FeatureCreated (Result Http.Error Feature.Feature)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateFeatureName str ->
            ( { model | featureNameInput = str }, Cmd.none )

        UpdateFeatureDescription str ->
            ( { model | featureDescriptionInput = str }, Cmd.none )

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

        EventsFetched (Ok evs) ->
            ( { model | events = evs }, Cmd.none )

        EventsFetched (Err e) ->
            ( { model | error = Just ("[Home - Events] Fetch failed: " ++ Debug.toString e) }, Cmd.none )

        FeatureCreated (Ok feature) ->
            ( { model | features = feature :: model.features, featureNameInput = "" }, Cmd.none )

        FeatureCreated (Err e) ->
            ( { model | error = Just ("Create failed: " ++ Debug.toString e) }, Cmd.none )

        FeaturesFetched (Ok features) ->
            ( { model | features = features }, Cmd.none )

        FeaturesFetched (Err e) ->
            ( { model | error = Just ("[Home - Features] Fetch failed: " ++ Debug.toString e) }, Cmd.none )


fetchEvents : Cmd Msg
fetchEvents =
    Http.get
        { url = "/api/events/"
        , expect = Http.expectJson EventsFetched (D.list Event.eventDecoder)
        }


fetchFeatures : Cmd Msg
fetchFeatures =
    Http.get
        { url = "/api/features/"
        , expect = Http.expectJson FeaturesFetched (D.list Feature.featureDecoder)
        }


view : Model -> Html Msg
view model =
    div []
        [ viewEvents model.events
        , viewFeatures model.features
        , viewCreateFeature model.featureNameInput model.featureDescriptionInput
        ]


viewEvents : List Event.Event -> Html Msg
viewEvents events =
    div [ class "events" ]
        [ h2 [] [ text "Events" ]
        , ul [] (List.map viewEvent (List.sortBy .name events))
        , a [ href "/event/" ] [ text "Create new event" ]
        ]


viewEvent : Event.Event -> Html Msg
viewEvent event =
    li [] [ a [ href ("/event/" ++ event.id) ] [ text ("[" ++ event.id ++ "] " ++ event.name) ] ]


viewFeatures : List Feature.Feature -> Html Msg
viewFeatures features =
    div [ class "features" ]
        [ h2 [] [ text "Features" ]
        , ul [] (List.map viewFeature (List.sortBy .name features))
        ]


viewFeature : Feature.Feature -> Html Msg
viewFeature feature =
    li []
        [ ul []
            [ li [] [ text feature.name ]
            , li [] [ text feature.description ]
            ]
        ]


viewCreateFeature : String -> String -> Html Msg
viewCreateFeature featureName featureDescription =
    div [ class "feature", class "create" ]
        [ input [ placeholder "Feature name", value featureName, onInput UpdateFeatureName ] []
        , textarea [ placeholder "Description", value featureDescription, onInput UpdateFeatureDescription ] []
        , button [ onClick SubmitFeature ] [ text "Create a feature" ]
        ]
