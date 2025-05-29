module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Json.Encode as Encode


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


type alias Model =
    { nameInput : String
    , events : List Event
    , error : Maybe String
    }


type Msg
    = UpdateName String
    | Submit
    | EventsFetched (Result Http.Error (List Event))
    | EventCreated (Result Http.Error Event)


init : () -> ( Model, Cmd Msg )
init _ =
    ( { nameInput = ""
      , events = []
      , error = Nothing
      }
    , fetchEvents
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateName str ->
            ( { model | nameInput = str }, Cmd.none )

        Submit ->
            let
                body =
                    Http.jsonBody <| eventEncoder { id = "", name = model.nameInput }
            in
            ( model
            , Http.post
                { url = "/api/events"
                , body = body
                , expect = Http.expectJson EventCreated eventDecoder
                }
            )

        EventCreated (Ok event) ->
            ( { model | events = event :: model.events, nameInput = "" }, Cmd.none )

        EventCreated (Err e) ->
            ( { model | error = Just ("Create failed: " ++ Debug.toString e) }, Cmd.none )

        EventsFetched (Ok evs) ->
            ( { model | events = evs }, Cmd.none )

        EventsFetched (Err e) ->
            ( { model | error = Just ("Fetch failed: " ++ Debug.toString e) }, Cmd.none )


fetchEvents : Cmd Msg
fetchEvents =
    Http.get
        { url = "/api/events"
        , expect = Http.expectJson EventsFetched (Decode.list eventDecoder)
        }


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Events" ]
        , ul [] (List.map (\e -> li [] [ text e.name ]) (List.sortBy .name model.events))
        , input [ placeholder "Event name", value model.nameInput, onInput UpdateName ] []
        , button [ onClick Submit ] [ text "Create an event" ]
        , case model.error of
            Just err ->
                div [ style "color" "red" ] [ text err ]

            Nothing ->
                text ""
        ]
