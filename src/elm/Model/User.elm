module Model.User exposing (User, decodeUser, encodeUser)

import Json.Decode as D
import Json.Encode as E


type alias User =
    { id : String
    , username : String
    , firstName : String
    , lastName : String
    }



-- SERIALIZATION


encodeUser : User -> E.Value
encodeUser user =
    E.object
        [ ( "id", E.string user.id )
        , ( "username", E.string user.username )
        , ( "firstName", E.string user.firstName )
        , ( "lastName", E.string user.lastName )
        ]


decodeUser : D.Decoder User
decodeUser =
    D.map4
        (\id username firstName lastName ->
            { id = id
            , username = username
            , firstName = firstName
            , lastName = lastName
            }
        )
        (D.field "id" D.string)
        (D.field "username" D.string)
        (D.field "firstName" D.string)
        (D.field "lastName" D.string)
