module Component.Markdown exposing
    ( fromMarkdown
    , fromMarkdownStyled
    , fromUnsanitizedMarkdown
    , fromUnsanitizedMarkdownStyled
    , markdownConfiguration
    )

import Component.DaisyUi as Ui
import Html.Styled as Dom
import Markdown
import Tailwind.Breakpoints as Br
import Tailwind.Classes as Cls
import Tailwind.Utilities as Tw



-- MODEL


markdownConfiguration : Markdown.Options
markdownConfiguration =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = True
    , smartypants = True
    }



-- VIEW


fromMarkdownBase : Bool -> List (Dom.Attribute msg) -> String -> Dom.Html msg
fromMarkdownBase sanitize attributes content =
    let
        result : Dom.Html msg
        result =
            Markdown.toHtmlWith
                { markdownConfiguration | sanitize = sanitize }
                []
                content
                |> Dom.fromUnstyled
    in
    Dom.article
        (Ui.mergeStyles
            [ ( [ Br.lg [ Tw.prose_lg ] ], [] )
            , Cls.prose_base
            ]
            attributes
        )
        [ result ]


fromUnsanitizedMarkdownStyled : List (Dom.Attribute msg) -> String -> Dom.Html msg
fromUnsanitizedMarkdownStyled =
    fromMarkdownBase False


fromUnsanitizedMarkdown : String -> Dom.Html msg
fromUnsanitizedMarkdown =
    fromUnsanitizedMarkdownStyled []


fromMarkdownStyled : List (Dom.Attribute msg) -> String -> Dom.Html msg
fromMarkdownStyled =
    fromMarkdownBase True


fromMarkdown : String -> Dom.Html msg
fromMarkdown =
    fromMarkdownStyled []
