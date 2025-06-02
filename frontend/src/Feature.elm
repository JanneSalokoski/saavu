module Feature exposing (..)

import Json.Decode as D
import Json.Encode as E


type alias Feature =
    { id : String
    , name : String
    , description : String
    }


featureDecoder : D.Decoder Feature
featureDecoder =
    D.map3 Feature
        (D.field "id" D.string)
        (D.field "name" D.string)
        (D.field "description" D.string)


featureEncoder : Feature -> E.Value
featureEncoder feature =
    E.object
        [ ( "name", E.string feature.name )
        , ( "description", E.string feature.description )
        ]
