module Extension.Url exposing (appendQueryDict, queryDict, removeQueryParameters, routeParts, setQueryDict)

{-| This module provides utility functions for working with URLs.

@docs appendQueryDict, queryDict, removeQueryParameters, routeParts, setQueryDict

-}

import Dict exposing (Dict)
import Maybe exposing (withDefault)
import Url exposing (Url)


{-| `routeParts` function takes a Url and returns a list of its path segments.
The segments are lowercased and empty segments are removed.

---

**For example**:

    import Url

    Maybe.map routeParts (Url.fromString "http://example.com/foo/bar")
    --> [ "foo", "bar" ] |> Just

    Maybe.map routeParts (Url.fromString "http://example.com/For//Example/")
    --> [ "for", "example" ] |> Just

    Maybe.map routeParts (Url.fromString "http://example.com/")
    --> [] |> Just

-}
routeParts : Url -> List String
routeParts url =
    String.toLower url.path
        |> String.split "/"
        |> List.filter
            (\part -> String.length part > 0)


{-| `queryDict` function takes a Url and returns a dictionary of its query parameters.

---

**For example**:

    import Dict
    import Url

    Maybe.map queryDict (Url.fromString "http://example.com?foo=bar&baz=qux")
    --> Dict.fromList [ ( "foo", "bar" ), ( "baz", "qux" ) ]
    -->    |> Just

    Maybe.map queryDict (Url.fromString "http://example.com/?foo=&bar=baz")
    --> Dict.fromList [ ( "foo", "" ), ( "bar", "baz" )]
    -->    |> Just

-}
queryDict : Url -> Dict String String
queryDict url =
    case url.query of
        Just query ->
            query
                |> String.split "&"
                |> List.map (String.split "=")
                |> List.map
                    (\pairs ->
                        case pairs of
                            [ key, value ] ->
                                ( Url.percentDecode key
                                , Url.percentDecode value
                                    |> withDefault ""
                                )

                            _ ->
                                ( Nothing, "" )
                    )
                |> List.filter (\( key, _ ) -> key /= Nothing)
                |> List.map (\( key, value ) -> ( withDefault "" key, value ))
                |> Dict.fromList

        Nothing ->
            Dict.empty


{-| `setQueryDict` function takes a dictionary of query parameters and a Url, and returns a new Url with the given query parameters.

---

**For example**:

    import Dict
    import Url

    Maybe.map
        (setQueryDict <| Dict.fromList [ ( "foo", "bar" ), ( "baz", "qux" ) ])
        (Url.fromString "http://example.com")
    --> Url.fromString "http://example.com?baz=qux&foo=bar"

-}
setQueryDict : Dict String String -> Url -> Url
setQueryDict dict url =
    let
        query : Maybe String
        query =
            if Dict.isEmpty dict then
                Nothing

            else
                Dict.toList dict
                    |> List.filter (\( key, _ ) -> not (String.isEmpty key))
                    |> List.map
                        (\( key, value ) ->
                            String.concat
                                [ Url.percentEncode key
                                , "="
                                , Url.percentEncode value
                                ]
                        )
                    |> String.join "&"
                    |> Just
    in
    { url | query = query }


{-| `appendQueryDict` function takes a dictionary of query parameters and a Url,
and returns a new Url with the given query parameters appended to the existing ones.
If a query parameter is already present in the Url, it will be replaced.
If the value of a query parameter is `Nothing`, it will be removed.

---

**For example**:

    import Dict
    import Url

    Maybe.map
        (appendQueryDict <| Dict.fromList [ ( "foo", Just "bar" ), ( "abc", Nothing ) ])
        (Url.fromString "http://example.com?baz=qux&abc=nope")
    --> Url.fromString "http://example.com?baz=qux&foo=bar"

    Maybe.map
        (appendQueryDict <| Dict.fromList [ ( " ", Just "foo" ), ("", Just "bar") ])
        (Url.fromString "http://example.com?baz=qux&abc=nope")
    --> Url.fromString "http://example.com?%20=foo&abc=nope&baz=qux"

-}
appendQueryDict : Dict String (Maybe String) -> Url -> Url
appendQueryDict dict url =
    let
        currentQuery : Dict String (Maybe String)
        currentQuery =
            queryDict url
                |> Dict.map (\_ -> Just)

        query : Dict String String
        query =
            Dict.union dict currentQuery
                |> Dict.filter (\_ value -> value /= Nothing)
                |> Dict.map (\_ -> withDefault "")
    in
    setQueryDict query url


{-| `removeQueryParameters` function takes a list of query parameter keys and a Url, and returns a new Url with the given query parameters removed.

---

**For example**:

    import Url

    Maybe.map
        (removeQueryParameters [ "foo" ])
        (Url.fromString "http://example.com?foo=bar&baz=qux")
    --> Url.fromString "http://example.com?baz=qux"

-}
removeQueryParameters : List String -> Url -> Url
removeQueryParameters keys url =
    let
        query : Dict String String
        query =
            List.foldl Dict.remove (queryDict url) keys
    in
    setQueryDict query url
