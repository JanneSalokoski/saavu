module Event exposing (..)

import Json.Decode as D
import Json.Encode as E


type alias Event =
    { id : String
    , name : String
    }


eventDecoder : D.Decoder Event
eventDecoder =
    D.map2 Event
        (D.field "id" D.string)
        (D.field "name" D.string)


eventEncoder : Event -> E.Value
eventEncoder event =
    E.object
        [ ( "name", E.string event.name ) ]
