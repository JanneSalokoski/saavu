module Pages.Home exposing (Model, Msg, init, noop, update, view)

import Event
import Feature
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D


type alias Model =
    { error : Maybe String
    }


noop : Model
noop =
    { error = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( { error = Nothing
      }
    , Cmd.none
    )


type Msg
    = Noop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )


view : Model -> Html Msg
view _ =
    div []
        [ p [] [ text "Show the accessibility information of your event in an accessible way!" ]
        , p [] [ text "Here we will have some more information about this." ]
        , a [ class "linkbutton", href "/event/" ] [ text "Create new event" ]
        ]
