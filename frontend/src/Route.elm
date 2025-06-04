module Route exposing (..)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>))


type Route
    = Home
    | Event String
    | CreateEvent
    | Admin
    | NotFound


routeParser : Parser.Parser (Route -> Route) Route
routeParser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Admin (Parser.s "admin")
        , Parser.map Event (Parser.s "event" </> Parser.string)
        , Parser.map CreateEvent (Parser.s "event")
        ]


fromUrl : Url -> Route
fromUrl url =
    Parser.parse routeParser url
        |> Maybe.withDefault NotFound
