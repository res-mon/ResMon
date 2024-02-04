module Component.Markdown exposing
    ( fromMarkdown
    , fromMarkdownStyled
    , fromUnsanitizedMarkdown
    , fromUnsanitizedMarkdownStyled
    , markdownConfiguration
    )

import Component.DaisyUi exposing (mergeStyles)
import Html.Styled exposing (Attribute, Html, article, fromUnstyled)
import Markdown
import Tailwind.Breakpoints exposing (lg)
import Tailwind.Classes exposing (prose_base)
import Tailwind.Utilities exposing (prose_lg)



-- MODEL


markdownConfiguration : Markdown.Options
markdownConfiguration =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = True
    , smartypants = True
    }



-- VIEW


fromMarkdownBase : Bool -> List (Attribute msg) -> String -> Html msg
fromMarkdownBase sanitize attributes content =
    let
        result : Html msg
        result =
            Markdown.toHtmlWith
                { markdownConfiguration | sanitize = sanitize }
                []
                content
                |> fromUnstyled
    in
    article
        (mergeStyles
            [ ( [ lg [ prose_lg ] ], [] )
            , prose_base
            ]
            attributes
        )
        [ result ]


fromUnsanitizedMarkdownStyled : List (Html.Styled.Attribute msg) -> String -> Html.Styled.Html msg
fromUnsanitizedMarkdownStyled =
    fromMarkdownBase False


fromUnsanitizedMarkdown : String -> Html msg
fromUnsanitizedMarkdown =
    fromUnsanitizedMarkdownStyled []


fromMarkdownStyled : List (Html.Styled.Attribute msg) -> String -> Html.Styled.Html msg
fromMarkdownStyled =
    fromMarkdownBase True


fromMarkdown : String -> Html msg
fromMarkdown =
    fromMarkdownStyled []
