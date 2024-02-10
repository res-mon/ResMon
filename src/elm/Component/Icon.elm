module Component.Icon exposing (bell, brightnessAltHigh, checkCircle, checkCircleFill, circleFill, columnsGap, exclamationCircleFill, exclamationTriangle, exclamationTriangleFill, fileEarmarkPdf, ico, infoCircle, infoCircleFill, list, moon, moonFill, palette, search, sun, sunFill, threeDots, xCircle, xLg)

import Css exposing (Style)
import Html.Styled as Dom
import Html.Styled.Attributes as Attr


list : List Style -> Dom.Html msg
list =
    ico "list"


search : List Style -> Dom.Html msg
search =
    ico "search"


bell : List Style -> Dom.Html msg
bell =
    ico "bell"


sun : List Style -> Dom.Html msg
sun =
    ico "sun"


moon : List Style -> Dom.Html msg
moon =
    ico "moon"


sunFill : List Style -> Dom.Html msg
sunFill =
    ico "sun-fill"


threeDots : List Style -> Dom.Html msg
threeDots =
    ico "three-dots"


moonFill : List Style -> Dom.Html msg
moonFill =
    ico "moon-fill"


brightnessAltHigh : List Style -> Dom.Html msg
brightnessAltHigh =
    ico "brightness-alt-high"


palette : List Style -> Dom.Html msg
palette =
    ico "palette"


fileEarmarkPdf : List Style -> Dom.Html msg
fileEarmarkPdf =
    ico "file-earmark-pdf"


infoCircleFill : List Style -> Dom.Html msg
infoCircleFill =
    ico "info-circle-fill"


infoCircle : List Style -> Dom.Html msg
infoCircle =
    ico "info-circle"


checkCircleFill : List Style -> Dom.Html msg
checkCircleFill =
    ico "check-circle-fill"


checkCircle : List Style -> Dom.Html msg
checkCircle =
    ico "check-circle"


exclamationCircleFill : List Style -> Dom.Html msg
exclamationCircleFill =
    ico "exclamation-circle-fill"


exclamationTriangle : List Style -> Dom.Html msg
exclamationTriangle =
    ico "exclamation-triangle"


xCircle : List Style -> Dom.Html msg
xCircle =
    ico "x-circle"


exclamationTriangleFill : List Style -> Dom.Html msg
exclamationTriangleFill =
    ico "exclamation-triangle-fill"


circleFill : List Style -> Dom.Html msg
circleFill =
    ico "circle-fill"


xLg : List Style -> Dom.Html msg
xLg =
    ico "x-lg"


columnsGap : List Style -> Dom.Html msg
columnsGap =
    ico "columns-gap"


ico : String -> List Style -> Dom.Html msg
ico name style =
    Dom.i [ Attr.class ("bi bi-" ++ name), Attr.css style ] []
