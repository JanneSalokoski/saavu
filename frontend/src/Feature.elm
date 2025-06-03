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


type alias FeatureWithRelation =
    { id : String
    , name : String
    , description : String
    , enabled : Bool
    }


featureWithRelationDecoder : D.Decoder FeatureWithRelation
featureWithRelationDecoder =
    D.map4 FeatureWithRelation
        (D.field "id" D.string)
        (D.field "name" D.string)
        (D.field "description" D.string)
        (D.field "enabled" D.bool)


featureWithRelationEncoder : FeatureWithRelation -> E.Value
featureWithRelationEncoder feature =
    E.object
        [ ( "id", E.string feature.id )
        , ( "name", E.string feature.name )
        , ( "description", E.string feature.description )
        , ( "enabled", E.bool feature.enabled )
        ]
