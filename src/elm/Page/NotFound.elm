module Page.NotFound exposing (view)

import Browser exposing (Document)
import Html.Styled exposing (Html, strong, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import List exposing (map)
import Model.Shared exposing (SharedModel)
import Tailwind.Utilities as U
import Url exposing (Url)



-- VIEW


view : SharedModel msg -> Document msg
view shared =
    { title = "Nicht gefunden"
    , body = map toUnstyled (mainContent shared.url)
    }


mainContent : Url -> List (Html msg)
mainContent url =
    [ text " Die angefragte Seite "
    , strong [ css [ U.font_bold ] ] [ text url.path ]
    , text " konnte nicht gefunden werden."
    ]
