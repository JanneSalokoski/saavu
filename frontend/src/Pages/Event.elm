module Pages.Event exposing (Model, Msg, init, noop, update, view)

import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D


type alias Model =
    { eventNameInput : String
    , event : Maybe Event.Event
    , features : List Feature.FeatureWithRelation
    , error : Maybe String
    }


noop : Model
noop =
    { eventNameInput = ""
    , event = Nothing
    , features = []
    , error = Nothing
    }


init : String -> ( Model, Cmd Msg )
init eventId =
    ( { eventNameInput = ""
      , event = Nothing
      , features = []
      , error = Nothing
      }
    , Cmd.batch
        [ fetchEvent eventId
        , fetchFeatures eventId
        ]
    )


type Msg
    = EventFetched (Result Http.Error Event.Event)
    | FeaturesFetched (Result Http.Error (List Feature.FeatureWithRelation))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventFetched (Ok event) ->
            ( { model | event = Just event }, Cmd.none )

        EventFetched (Err e) ->
            ( { model | event = Nothing, error = Just ("[Event - Events] Fetch failed: " ++ Debug.toString e) }, Cmd.none )

        FeaturesFetched (Ok features) ->
            ( { model | features = features }, Cmd.none )

        FeaturesFetched (Err e) ->
            ( { model | event = Nothing, error = Just ("[Event - Features] Fetch failed: " ++ Debug.toString e) }
            , Cmd.none
            )


fetchEvent : String -> Cmd Msg
fetchEvent id =
    Http.get
        { url = "/api/events/" ++ id
        , expect =
            Http.expectJson EventFetched Event.eventDecoder
        }


fetchFeatures : String -> Cmd Msg
fetchFeatures eventId =
    Http.get
        { url = "/api/feature_relations/" ++ eventId
        , expect =
            Http.expectJson FeaturesFetched (D.list Feature.featureWithRelationDecoder)
        }


view : Model -> Html Msg
view model =
    div []
        [ viewEvent model.event
        , viewFeatures model.features
        ]


viewEvent : Maybe Event.Event -> Html Msg
viewEvent event =
    case event of
        Just ev ->
            ul [ class "Event" ]
                [ li [] [ text ("id: " ++ ev.id) ]
                , li [] [ text ("name: " ++ ev.name) ]
                ]

        Nothing ->
            div [ class "Event" ]
                [ text "Event not found"
                ]


viewFeatures : List Feature.FeatureWithRelation -> Html Msg
viewFeatures features =
    div [ class "Features" ]
        [ h2 [] [ text "Features" ]
        , ul [ class "feature-grid" ] (List.map viewFeature (List.sortBy .name features))
        ]


viewFeature : Feature.FeatureWithRelation -> Html Msg
viewFeature feature =
    li []
        [ ul [ class "Feature", classList [ ( "enabled", feature.enabled ) ] ]
            [ li [] [ text feature.name ]
            , li [] [ text feature.description ]
            ]
        ]
