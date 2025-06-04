module Pages.CreateEvent exposing (Model, Msg, init, noop, update, view)

import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as D
import Relation


type alias Model =
    { eventNameInput : String
    , features : List Feature.Feature
    , selected : List String
    , id : Maybe String
    , error : Maybe String
    }


noop : Model
noop =
    { eventNameInput = ""
    , features = []
    , selected = []
    , id = Nothing
    , error = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( { eventNameInput = ""
      , features = []
      , selected = []
      , id = Nothing
      , error = Nothing
      }
    , fetchFeatures
    )


submitRelations : Model -> Cmd Msg
submitRelations model =
    let
        relationObjects =
            case model.id of
                Just id ->
                    List.map (\a -> { feature_id = a, event_id = id }) model.selected

                _ ->
                    []

        body =
            Http.jsonBody <| Relation.relationsEncoder relationObjects
    in
    Http.post
        { url = "/api/feature_relations/"
        , body = body
        , expect = Http.expectJson RelationsCreated Relation.relationsDecoder
        }


type Msg
    = UpdateEventName String
    | ToggleSelected String
    | SubmitEvent
    | SubmitRelations
    | EventCreated (Result Http.Error Event.Event)
    | FeaturesFetched (Result Http.Error (List Feature.Feature))
    | RelationsCreated (Result Http.Error (List Relation.Relation))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateEventName str ->
            ( { model | eventNameInput = str }, Cmd.none )

        ToggleSelected id ->
            let
                newSelected =
                    if List.any (\a -> a == id) model.selected then
                        List.filter (\a -> a /= id) model.selected

                    else
                        id :: model.selected
            in
            ( { model | selected = newSelected }, Cmd.none )

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

        SubmitRelations ->
            let
                relationObjects =
                    case model.id of
                        Just id ->
                            List.map (\a -> { feature_id = a, event_id = id }) model.selected

                        _ ->
                            []

                body =
                    Http.jsonBody <| Relation.relationsEncoder relationObjects
            in
            ( model
            , Http.post
                { url = "/api/feature_relations/"
                , body = body
                , expect = Http.expectJson RelationsCreated Relation.relationsDecoder
                }
            )

        EventCreated (Ok event) ->
            ( { model | eventNameInput = "", id = Just event.id }, submitRelations { model | id = Just event.id } )

        EventCreated (Err e) ->
            ( { model | error = Just ("Create failed: " ++ Debug.toString e) }, Cmd.none )

        RelationsCreated _ ->
            ( model, Cmd.none )

        FeaturesFetched (Ok features) ->
            ( { model | features = features }, Cmd.none )

        FeaturesFetched (Err e) ->
            ( { model | error = Just ("[CreateEvent - Features] Fetch failed: " ++ Debug.toString e) }, Cmd.none )


fetchFeatures : Cmd Msg
fetchFeatures =
    Http.get
        { url = "/api/features/"
        , expect = Http.expectJson FeaturesFetched (D.list Feature.featureDecoder)
        }


view : Model -> Html Msg
view model =
    div []
        [ viewCreateEvent model.eventNameInput
        , viewFeatures model.features model.selected

        -- , viewSelected model.selected
        ]


viewCreateEvent : String -> Html Msg
viewCreateEvent eventName =
    Html.form [ class "CreateEvent", onSubmit SubmitEvent ]
        [ input [ class "name", placeholder "Event name", value eventName, onInput UpdateEventName ] []
        , button [ class "submit", type_ "submit" ] [ text "Create an event" ]
        ]


viewFeatures : List Feature.Feature -> List String -> Html Msg
viewFeatures features selected =
    div [ class "Features" ]
        [ h2 [] [ text "Features" ]
        , ul [ class "feature-grid" ] (List.map (viewFeature selected) (List.sortBy .name features))
        ]


viewFeature : List String -> Feature.Feature -> Html Msg
viewFeature selected feature =
    let
        isSelected =
            List.any (\a -> a == feature.id) selected
    in
    li [ class "Feature", tabindex 1, attribute "role" "button", style "cursor" "pointer", onClick (ToggleSelected feature.id), classList [ ( "enabled", isSelected ) ] ]
        [ ul []
            [ li [ class "name" ] [ text feature.name ]
            , li [ class "description" ] [ text feature.description ]
            ]
        ]


viewSelected : List String -> Html Msg
viewSelected selected =
    div []
        [ span [] [ text "Selected: " ]
        , ul []
            (List.map
                (\a -> li [] [ text a ])
                (List.sort selected)
            )
        ]
