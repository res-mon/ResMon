module Elm.Extension.Url exposing (all)

{-| This module contains tests for the `Extension.Url` mmodule.

@docs all

-}

import Dict exposing (Dict)
import Expect
import Extension.Url exposing (appendQueryDict, queryDict, removeQueryParameters, routeParts, setQueryDict)
import Fuzz
import Test exposing (Test, describe, fuzz, test)
import Url



-- MODEL


type Action
    = Append
    | Set
    | Remove


allActions : List Action
allActions =
    [ Append, Set, Remove ]



-- FUZZER


pathFuzzer : Fuzz.Fuzzer String
pathFuzzer =
    Fuzz.string
        |> Fuzz.map
            (stringReplaceAll
                [ ( "/", "%2F" )
                , ( "#", "%23" )
                , ( "?", "%3F" )
                , ( "&", "%26" )
                , ( "=", "%3D" )
                ]
            )


pathListFuzzer : Fuzz.Fuzzer (List String)
pathListFuzzer =
    Fuzz.list pathFuzzer


queryStringFuzzer : Fuzz.Fuzzer String
queryStringFuzzer =
    Fuzz.list
        (Fuzz.map2
            (\key value -> String.concat [ key, "=", value ])
            (Fuzz.map Url.percentEncode Fuzz.string)
            (Fuzz.map Url.percentEncode Fuzz.string)
        )
        |> Fuzz.map (String.join "&")


queryDictFuzzer : Fuzz.Fuzzer (Dict String (Maybe String))
queryDictFuzzer =
    Fuzz.map2
        (\key value ->
            ( key, value )
        )
        (Fuzz.stringOfLengthBetween 0 4)
        (Fuzz.maybe Fuzz.string)
        |> Fuzz.listOfLengthBetween 0 4
        |> Fuzz.map Dict.fromList


actionFuzzer : Fuzz.Fuzzer Action
actionFuzzer =
    Fuzz.oneOfValues allActions


queryDictActionsFuzzer : Fuzz.Fuzzer (List ( Dict String (Maybe String), Action ))
queryDictActionsFuzzer =
    Fuzz.map2
        (\dict action -> ( dict, action ))
        queryDictFuzzer
        actionFuzzer
        |> Fuzz.list



-- UTILITIES


filterEmptyDict : Dict String (Maybe String) -> Dict String String
filterEmptyDict dict =
    Dict.filter
        (\_ value ->
            value /= Nothing
        )
        dict
        |> Dict.map (\_ value -> Maybe.withDefault "" value)


makeDictOptional : Dict String String -> Dict String (Maybe String)
makeDictOptional dict =
    Dict.map (\_ value -> Just value) dict


removeDictKeys :
    Dict String a
    -> Dict String b
    -> Dict String b
removeDictKeys keys dict =
    List.foldl
        (\key acc ->
            Dict.remove key acc
        )
        dict
        (Dict.keys keys)


stringReplaceAll : List ( String, String ) -> String -> String
stringReplaceAll replacements input =
    List.foldl (\( from, to ) -> String.replace from to) input replacements



-- TESTS


{-| Tests all exposed functions in the `Extension.Url` module.
-}
all : Test
all =
    describe "Extension.Url Tests"
        [ routePartsTests
        , queryDictTests
        , setQueryDictTests
        , appendQueryDictTests
        , removeQueryParametersTests
        , appendSetRemoveQueryTests
        ]


routePartsTests : Test
routePartsTests =
    describe "routeParts"
        [ test "Empty path returns empty list" <|
            \_ ->
                Expect.equal
                    (Maybe.map routeParts <|
                        Url.fromString "http://example.com"
                    )
                <|
                    Just []
        , test "Path with segments returns correct list" <|
            \_ ->
                Expect.equal
                    (Maybe.map routeParts <|
                        Url.fromString "http://example.com/foo/bar"
                    )
                <|
                    Just [ "foo", "bar" ]
        , fuzz pathListFuzzer "Fuzz test for routeParts" <|
            \parts ->
                let
                    expectation : List String
                    expectation =
                        List.map String.toLower parts
                            |> List.filter (\part -> String.isEmpty part |> not)

                    justResult : List String
                    justResult =
                        Maybe.withDefault [] result

                    result : Maybe (List String)
                    result =
                        Maybe.map routeParts url

                    url : Maybe Url.Url
                    url =
                        Url.fromString urlString

                    urlString : String
                    urlString =
                        "http://example.com/" ++ String.join "/" parts
                in
                Expect.all
                    [ -- Make sure the result is what we expect
                      \_ -> Expect.equal (Just expectation) result
                    , -- Make sure the result contains no empty strings
                      \_ ->
                        Expect.equal
                            (List.filter
                                (\part -> String.isEmpty part |> not)
                                justResult
                            )
                            justResult
                    , -- Make sure the result is all lowercase
                      \_ ->
                        Expect.equal
                            (List.map String.toLower justResult)
                            justResult
                    ]
                    ()
        ]


queryDictTests : Test
queryDictTests =
    describe "queryDict"
        [ test "Converts query string to dictionary" <|
            \_ ->
                Expect.equal
                    (Maybe.map queryDict <|
                        Url.fromString "http://example.com?foo=bar&baz=qux"
                    )
                    (Just <|
                        Dict.fromList [ ( "foo", "bar" ), ( "baz", "qux" ) ]
                    )
        , test "Decodes percent-encoded keys and values" <|
            \_ ->
                Expect.equal
                    (Maybe.map queryDict <|
                        Url.fromString "http://example.com?foo%20=bar%25"
                    )
                    (Just <| Dict.fromList [ ( "foo ", "bar%" ) ])
        , test "Handles empty query string" <|
            \_ ->
                Expect.equal
                    (Maybe.map queryDict <|
                        Url.fromString "http://example.com"
                    )
                    (Just <| Dict.empty)
        , fuzz queryStringFuzzer "queryDict Fuzz test" <|
            \queryString ->
                let
                    actualDict : Maybe (Dict String String)
                    actualDict =
                        Maybe.map queryDict (Url.fromString urlString)

                    emptyDict : Dict String String
                    emptyDict =
                        Dict.empty

                    expectedDict : Dict String String
                    expectedDict =
                        queryParameters
                            |> List.foldl
                                (\pair acc ->
                                    case pair of
                                        [ key, value ] ->
                                            case ( Url.percentDecode key, Url.percentDecode value ) of
                                                ( Just k, Just v ) ->
                                                    Dict.insert k v acc

                                                _ ->
                                                    acc

                                        _ ->
                                            acc
                                )
                                emptyDict

                    queryParameters : List (List String)
                    queryParameters =
                        queryString
                            |> String.split "&"
                            |> List.map (\param -> String.split "=" param)

                    urlString : String
                    urlString =
                        "http://example.com/?" ++ queryString
                in
                Expect.equal (Just expectedDict) actualDict
        ]


setQueryDictTests : Test
setQueryDictTests =
    describe "setQueryDict"
        [ test "Sets query parameters from a dictionary" <|
            \_ ->
                Expect.equal
                    (Maybe.map
                        (Url.toString
                            << setQueryDict (Dict.fromList [ ( "foo", "bar" ), ( "baz", "qux" ) ])
                        )
                     <|
                        Url.fromString "http://example.com"
                    )
                    (Just "http://example.com/?baz=qux&foo=bar")
        , test "Replaces existing query parameters" <|
            \_ ->
                Expect.equal
                    (Maybe.map
                        (Url.toString
                            << setQueryDict (Dict.fromList [ ( "new", "value" ) ])
                        )
                     <|
                        Url.fromString "http://example.com?foo=bar"
                    )
                    (Just "http://example.com/?new=value")
        ]


appendQueryDictTests : Test
appendQueryDictTests =
    describe "appendQueryDict"
        [ test "Appends and replaces query parameters" <|
            \_ ->
                Expect.equal
                    (Maybe.map
                        (Url.toString
                            << appendQueryDict (Dict.fromList [ ( "foo", Just "new" ), ( "new", Just "value" ) ])
                        )
                     <|
                        Url.fromString "http://example.com?foo=bar&baz=qux"
                    )
                    (Just "http://example.com/?baz=qux&foo=new&new=value")
        , test "Removes query parameter if value is Nothing" <|
            \_ ->
                Expect.equal
                    (Maybe.map
                        (Url.toString
                            << appendQueryDict (Dict.fromList [ ( "foo", Nothing ) ])
                        )
                     <|
                        Url.fromString "http://example.com?foo=bar&baz=qux"
                    )
                    (Just "http://example.com/?baz=qux")
        ]


removeQueryParametersTests : Test
removeQueryParametersTests =
    describe "removeQueryParameters"
        [ test "Removes specified query parameters" <|
            \_ ->
                Expect.equal
                    (Maybe.map
                        (Url.toString
                            << removeQueryParameters [ "foo" ]
                        )
                     <|
                        Url.fromString "http://example.com?foo=bar&baz=qux"
                    )
                    (Just "http://example.com/?baz=qux")
        , test "Leaves URL unchanged if parameter not present" <|
            \_ ->
                Expect.equal
                    (Maybe.map
                        (Url.toString
                            << removeQueryParameters [ "notThere" ]
                        )
                     <|
                        Url.fromString "http://example.com?foo=bar"
                    )
                    (Just "http://example.com/?foo=bar")
        ]


appendSetRemoveQueryTests : Test
appendSetRemoveQueryTests =
    fuzz queryDictActionsFuzzer "appendQueryDict, setQueryDict, removeQueryParameters" <|
        \actions ->
            let
                actual : Url.Url -> Dict String String
                actual baseUrl =
                    List.foldl
                        (\( actionValue, action ) url ->
                            case action of
                                Append ->
                                    appendQueryDict actionValue url

                                Set ->
                                    removeQueryParameters (Dict.filter (\_ value -> value == Nothing) actionValue |> Dict.keys) url
                                        |> setQueryDict (filterEmptyDict actionValue)

                                Remove ->
                                    removeQueryParameters (Dict.keys actionValue) url
                        )
                        baseUrl
                        actions
                        |> queryDict

                empty : Dict String String
                empty =
                    Dict.empty

                emptyUrl : Maybe Url.Url
                emptyUrl =
                    Url.fromString "http://example.com"

                expected : Dict String String
                expected =
                    List.foldl
                        (\( actionValue, action ) dict ->
                            case action of
                                Append ->
                                    makeDictOptional dict
                                        |> Dict.union actionValue
                                        |> filterEmptyDict

                                Set ->
                                    filterEmptyDict actionValue

                                Remove ->
                                    removeDictKeys actionValue dict
                        )
                        empty
                        actions
                        |> Dict.filter (\key _ -> key /= "")
            in
            Expect.equal
                (Just expected)
                (Maybe.map actual emptyUrl)
