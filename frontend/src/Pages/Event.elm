module Pages.Event exposing (Model, Msg, init, update, view)

import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode


type alias Model =
    { eventNameInput : String
    , event : Maybe Event.Event
    , featureNameInput : String
    , featureDescriptionInput : String
    , features : List Feature.Feature
    , error : Maybe String
    }


init : String -> ( Model, Cmd Msg )
init id =
    ( { eventNameInput = ""
      , featureNameInput = ""
      , featureDescriptionInput = ""
      , event = Nothing
      , features = []
      , error = Nothing
      }
    , Cmd.batch
        [ fetchEvent id
        ]
    )


type Msg
    = EventFetched (Result Http.Error Event.Event)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventFetched (Ok event) ->
            ( { model | event = Just event }, Cmd.none )

        EventFetched (Err e) ->
            ( { model | event = Nothing, error = Just ("Fetch failed: " ++ Debug.toString e) }, Cmd.none )


fetchEvent : String -> Cmd Msg
fetchEvent id =
    Http.get
        { url = "/api/events/" ++ id
        , expect =
            Http.expectJson EventFetched Event.eventDecoder
        }


view : Model -> Html Msg
view model =
    div []
        [ viewEvent model.event
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
