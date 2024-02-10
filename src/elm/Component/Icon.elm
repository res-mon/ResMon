module Component.Icon exposing (bell, brightnessAltHigh, checkCircle, checkCircleFill, circleFill, columnsGap, exclamationCircleFill, exclamationTriangle, exclamationTriangleFill, fileEarmarkPdf, ico, infoCircle, infoCircleFill, list, moon, moonFill, palette, search, sun, sunFill, threeDots, xCircle, xLg)

import Css exposing (Style)
import Html.Styled exposing (Html, i)
import Html.Styled.Attributes exposing (class, css)


list : List Style -> Html msg
list =
    ico "list"


search : List Style -> Html msg
search =
    ico "search"


bell : List Style -> Html msg
bell =
    ico "bell"


sun : List Style -> Html msg
sun =
    ico "sun"


moon : List Style -> Html msg
moon =
    ico "moon"


sunFill : List Style -> Html msg
sunFill =
    ico "sun-fill"


threeDots : List Style -> Html msg
threeDots =
    ico "three-dots"


moonFill : List Style -> Html msg
moonFill =
    ico "moon-fill"


brightnessAltHigh : List Style -> Html msg
brightnessAltHigh =
    ico "brightness-alt-high"


palette : List Style -> Html msg
palette =
    ico "palette"


fileEarmarkPdf : List Style -> Html msg
fileEarmarkPdf =
    ico "file-earmark-pdf"


infoCircleFill : List Style -> Html msg
infoCircleFill =
    ico "info-circle-fill"


infoCircle : List Style -> Html msg
infoCircle =
    ico "info-circle"


checkCircleFill : List Style -> Html msg
checkCircleFill =
    ico "check-circle-fill"


checkCircle : List Style -> Html msg
checkCircle =
    ico "check-circle"


exclamationCircleFill : List Style -> Html msg
exclamationCircleFill =
    ico "exclamation-circle-fill"


exclamationTriangle : List Style -> Html msg
exclamationTriangle =
    ico "exclamation-triangle"


xCircle : List Style -> Html msg
xCircle =
    ico "x-circle"


exclamationTriangleFill : List Style -> Html msg
exclamationTriangleFill =
    ico "exclamation-triangle-fill"


circleFill : List Style -> Html msg
circleFill =
    ico "circle-fill"


xLg : List Style -> Html msg
xLg =
    ico "x-lg"


columnsGap : List Style -> Html msg
columnsGap =
    ico "columns-gap"


ico : String -> List Style -> Html msg
ico name style =
    i [ class ("bi bi-" ++ name), css style ] []
