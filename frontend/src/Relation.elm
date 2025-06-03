module Relation exposing (..)

import Json.Decode as D
import Json.Encode as E


type alias Relation =
    { feature_id : String
    , event_id : String
    }


relationDecoder : D.Decoder Relation
relationDecoder =
    D.map2 Relation
        (D.field "feature_id" D.string)
        (D.field "event_id" D.string)


relationsDecoder : D.Decoder (List Relation)
relationsDecoder =
    D.list relationDecoder


relationEncoder : Relation -> E.Value
relationEncoder relation =
    E.object
        [ ( "feature_id", E.string relation.feature_id )
        , ( "event_id", E.string relation.event_id )
        ]


relationsEncoder : List Relation -> E.Value
relationsEncoder relations =
    E.list relationEncoder relations
