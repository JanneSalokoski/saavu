module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Json.Encode as Encode


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Event =
    { id : String
    , name : String
    }


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.map2 Event
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)


eventEncoder : Event -> Encode.Value
eventEncoder event =
    Encode.object
        [ ( "name", Encode.string event.name ) ]


type alias Feature =
    { id : String
    , name : String
    , description : String
    }


featureDecoder : Decode.Decoder Feature
featureDecoder =
    Decode.map3 Feature
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)


featureEncoder : Feature -> Encode.Value
featureEncoder feature =
    Encode.object
        [ ( "name", Encode.string feature.name )
        , ( "description", Encode.string feature.description )
        ]


type alias Model =
    { eventNameInput : String
    , events : List Event
    , featureNameInput : String
    , featureDescriptionInput : String
    , features : List Feature
    , error : Maybe String
    }


type Msg
    = UpdateEventName String
    | UpdateFeatureName String
    | UpdateFeatureDescription String
    | SubmitEvent
    | SubmitFeature
    | EventsFetched (Result Http.Error (List Event))
    | EventCreated (Result Http.Error Event)
    | FeaturesFetched (Result Http.Error (List Feature))
    | FeatureCreated (Result Http.Error Feature)


init : () -> ( Model, Cmd Msg )
init _ =
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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


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
                    Http.jsonBody <| eventEncoder { id = "", name = model.eventNameInput }
            in
            ( model
            , Http.post
                { url = "/api/events"
                , body = body
                , expect = Http.expectJson EventCreated eventDecoder
                }
            )

        SubmitFeature ->
            let
                body =
                    Http.jsonBody <| featureEncoder { id = "", name = model.featureNameInput, description = model.featureDescriptionInput }
            in
            ( model
            , Http.post
                { url = "/api/features"
                , body = body
                , expect = Http.expectJson FeatureCreated featureDecoder
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
        , expect = Http.expectJson EventsFetched (Decode.list eventDecoder)
        }


fetchFeatures : Cmd Msg
fetchFeatures =
    Http.get
        { url = "/api/features"
        , expect = Http.expectJson FeaturesFetched (Decode.list featureDecoder)
        }


view : Model -> Html Msg
view model =
    div []
        [ viewEvents model.events
        , viewCreateEvent model.eventNameInput
        , viewFeatures model.features
        , viewCreateFeature model.featureNameInput model.featureDescriptionInput
        , viewErrorDialog model.error
        ]


viewEvents : List Event -> Html Msg
viewEvents events =
    div [ class "events" ]
        [ h2 [] [ text "Events" ]
        , ul [] (List.map viewEvent (List.sortBy .name events))
        ]


viewEvent : Event -> Html Msg
viewEvent event =
    li [] [ text event.name ]


viewCreateEvent : String -> Html Msg
viewCreateEvent eventName =
    div []
        [ input [ placeholder "Event name", value eventName, onInput UpdateEventName ] []
        , button [ onClick SubmitEvent ] [ text "Create an event" ]
        ]


viewFeatures : List Feature -> Html Msg
viewFeatures features =
    div [ class "features" ]
        [ h2 [] [ text "Features" ]
        , ul [] (List.map viewFeature (List.sortBy .name features))
        ]


viewFeature : Feature -> Html Msg
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
