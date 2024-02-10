module Page.NotFound exposing (view)

import Browser exposing (Document)
import Html.Styled as Dom
import Html.Styled.Attributes as Attr
import List exposing (map)
import Model.Shared exposing (SharedModel)
import Tailwind.Utilities as Tw
import Url exposing (Url)



-- VIEW


view : SharedModel msg -> Document msg
view shared =
    { title = "Nicht gefunden"
    , body = map Dom.toUnstyled (mainContent shared.url)
    }


mainContent : Url -> List (Dom.Html msg)
mainContent url =
    [ Dom.text " Die angefragte Seite "
    , Dom.strong [ Attr.css [ Tw.font_bold ] ] [ Dom.text url.path ]
    , Dom.text " konnte nicht gefunden werden."
    ]
