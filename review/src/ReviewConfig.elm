module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import CognitiveComplexity
import Docs.NoMissing exposing (allModules, onlyExposed)
import Docs.ReviewAtDocs
import Docs.ReviewLinksAndSections
import Docs.UpToDateReadmeLinks
import EqualsCaseable
import LimitAliasedRecordSize
import List
import MultipleAppendToConcat
import NoAlways
import NoBooleanCase
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDeprecated
import NoDuplicatePorts
import NoEmptyText
import NoEtaReducibleLambdas
import NoExposingEverything
import NoImportingEverything
import NoLongImportLines
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeConstructor
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoPrimitiveTypeAlias
import NoRecordAliasConstructor
import NoRecursiveUpdate
import NoRedundantConcat
import NoRegex
import NoSimpleLetBody
import NoSinglePatternCase
import NoUnmatchedUnit
import NoUnnecessaryTrailingUnderscore
import NoUnoptimizedRecursion
import NoUnsafeDivision
import NoUnsafePorts
import NoUnsortedCases
import NoUnsortedLetDeclarations
import NoUnsortedRecords
import NoUnsortedTopLevelDeclarations
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnusedPorts
import NoUselessSubscriptions
import Review.Rule as Rule exposing (Rule)
import Simplify
import UseCamelCase
import UseMemoizedLazyLambda


config : List Rule
config =
    [ CognitiveComplexity.rule 7 -- https://package.elm-lang.org/packages/jfmengels/elm-review-cognitive-complexity/latest/CognitiveComplexity/

    -- https://package.elm-lang.org/packages/jfmengels/elm-review-documentation/latest/Docs-NoMissing/
    , Docs.NoMissing.rule
        { document = onlyExposed
        , from = allModules
        }
        |> Rule.ignoreErrorsForFiles
            [ "src/elm/Component/DaisyUi.elm"
            , "src/elm/Component/Form.elm"
            , "src/elm/Component/Icon.elm"
            , "src/elm/Component/Markdown.elm"
            , "src/elm/LocalStorage.elm"
            , "src/elm/Main.elm"
            , "src/elm/Model/Shared.elm"
            , "src/elm/Model/User.elm"
            , "src/elm/Page/Layout.elm"
            , "src/elm/Page/NotFound.elm"
            , "src/elm/Routing.elm"
            ]
    , Docs.ReviewAtDocs.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-documentation/latest/Docs-ReviewAtDocs/
    , Docs.ReviewLinksAndSections.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-documentation/latest/Docs-ReviewLinksAndSections/
    , Docs.UpToDateReadmeLinks.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-documentation/latest/Docs-UpToDateReadmeLinks/
    , EqualsCaseable.forbid EqualsCaseable.InIf -- https://package.elm-lang.org/packages/lue-bird/elm-review-equals-caseable/latest/EqualsCaseable
    , LimitAliasedRecordSize.rule (16 |> LimitAliasedRecordSize.maxRecordSize) -- https://package.elm-lang.org/packages/matzko/elm-review-limit-aliased-record-size/latest/LimitAliasedRecordSize
    , MultipleAppendToConcat.rule MultipleAppendToConcat.PipeRightList -- https://package.elm-lang.org/packages/lue-bird/elm-review-multiple-append-to-concat/latest/MultipleAppendToConcat
    , NoAlways.rule -- https://package.elm-lang.org/packages/sparksp/elm-review-always/latest/NoAlways
    , NoBooleanCase.rule -- https://package.elm-lang.org/packages/truqu/elm-review-nobooleancase/latest/NoBooleanCase
    , NoConfusingPrefixOperator.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoConfusingPrefixOperator/
    , NoDebug.Log.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-debug/latests/NoDebug-Log/
    , NoDebug.TodoOrToString.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-debug/latest/NoDebug-TodoOrToString/
    , NoDeprecated.rule NoDeprecated.defaults -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoDeprecated/
    , NoDuplicatePorts.rule -- https://package.elm-lang.org/packages/sparksp/elm-review-ports/latest/NoDuplicatePorts
    , NoEmptyText.rule -- https://package.elm-lang.org/packages/leojpod/review-no-empty-html-text/latest/NoEmptyText

    -- https://package.elm-lang.org/packages/jsuder-xx/elm-review-reducible-lambdas/latest/NoEtaReducibleLambdas
    , NoEtaReducibleLambdas.rule
        { lambdaReduceStrategy = NoEtaReducibleLambdas.AlwaysRemoveLambdaWhenPossible
        , argumentNamePredicate = always True
        }
    , NoExposingEverything.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoExposingEverything/
    , NoImportingEverything.rule [] -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoImportingEverything/
    , NoLongImportLines.rule -- https://package.elm-lang.org/packages/r-k-b/no-long-import-lines/latest/NoLongImportLines
    , NoMissingSubscriptionsCall.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-the-elm-architecture/latest/NoMissingSubscriptionsCall
    , NoMissingTypeAnnotation.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoMissingTypeAnnotation/
    , NoMissingTypeAnnotationInLetIn.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoMissingTypeAnnotationInLetIn
    , NoMissingTypeConstructor.rule -- https://package.elm-lang.org/packages/Arkham/elm-review-no-missing-type-constructor/latest/NoMissingTypeConstructor
    , NoMissingTypeExpose.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoMissingTypeExpose/
    , NoPrematureLetComputation.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-common/latest/NoPrematureLetComputation/
    , NoPrimitiveTypeAlias.rule -- https://package.elm-lang.org/packages/dillonkearns/elm-review-no-primitive-type-alias/latest/NoPrimitiveTypeAlias
    , NoRecordAliasConstructor.rule -- https://package.elm-lang.org/packages/lue-bird/elm-review-record-alias-constructor/latest/NoRecordAliasConstructor
    , NoRecursiveUpdate.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-the-elm-architecture/latest/NoRecursiveUpdate
    , NoRedundantConcat.rule -- https://package.elm-lang.org/packages/truqu/elm-review-noredundantconcat/latest/NoRedundantConcat
    , NoRegex.rule -- https://package.elm-lang.org/packages/ContaSystemer/elm-review-no-regex/latest/NoRegex
    , NoSimpleLetBody.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-code-style/latest/NoSimpleLetBody/
    , NoSinglePatternCase.rule NoSinglePatternCase.fixInArgument -- https://package.elm-lang.org/packages/SiriusStarr/elm-review-no-single-pattern-case/latest/NoSinglePatternCase/
    , NoUnmatchedUnit.rule -- https://package.elm-lang.org/packages/mthadley/elm-review-unit/latest/NoUnmatchedUnit
    , NoUnnecessaryTrailingUnderscore.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-code-style/latest/NoUnnecessaryTrailingUnderscore/
    , NoUnoptimizedRecursion.rule (NoUnoptimizedRecursion.optOutWithComment "IGNORE TCO") -- https://package.elm-lang.org/packages/jfmengels/elm-review-performance/latest/NoUnoptimizedRecursion/
    , NoUnsafeDivision.rule -- https://package.elm-lang.org/packages/vkfisher/elm-review-no-unsafe-division/latest/NoUnsafeDivision
    , NoUnsafePorts.rule NoUnsafePorts.any -- https://package.elm-lang.org/packages/sparksp/elm-review-ports/latest/NoUnsafePorts
    , NoUnsortedCases.rule NoUnsortedCases.defaults -- https://package.elm-lang.org/packages/SiriusStarr/elm-review-no-unsorted/latest/NoUnsortedCases/

    -- https://package.elm-lang.org/packages/SiriusStarr/elm-review-no-unsorted/latest/NoUnsortedLetDeclarations/
    , NoUnsortedLetDeclarations.rule
        (NoUnsortedLetDeclarations.sortLetDeclarations
            |> NoUnsortedLetDeclarations.alphabetically
        )

    -- https://package.elm-lang.org/packages/SiriusStarr/elm-review-no-unsorted/latest/NoUnsortedRecords/
    , NoUnsortedRecords.rule
        (NoUnsortedRecords.defaults
            |> NoUnsortedRecords.reportAmbiguousRecordsWithoutFix
        )

    {- Stack overflow whith this rule enabled

       -- https://package.elm-lang.org/packages/SiriusStarr/elm-review-no-unsorted/latest/NoUnsortedTopLevelDeclarations/
          , NoUnsortedTopLevelDeclarations.rule
              (NoUnsortedTopLevelDeclarations.sortTopLevelDeclarations
                  |> NoUnsortedTopLevelDeclarations.portsFirst
                  |> NoUnsortedTopLevelDeclarations.exposedOrderWithPrivateLast
                  |> NoUnsortedTopLevelDeclarations.alphabetically
              )
    -}
    , NoUnused.CustomTypeConstructorArgs.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-CustomTypeConstructorArgs/

    -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-CustomTypeConstructors/
    , NoUnused.CustomTypeConstructors.rule []
        |> Rule.ignoreErrorsForFiles
            [ "src/elm/Component/DaisyUi.elm"
            , "src/elm/Model/Shared.elm"
            ]
    , NoUnused.Dependencies.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-Dependencies/

    -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-Exports/
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForFiles
            [ "src/elm/Component/DaisyUi.elm"
            , "src/elm/Component/Form.elm"
            , "src/elm/Component/Icon.elm"
            , "src/elm/Component/Markdown.elm"
            , "src/elm/Extension/Time.elm"
            , "src/elm/LocalStorage.elm"
            , "src/elm/Model/User.elm"
            ]
    , NoUnused.Parameters.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-Parameters/
    , NoUnused.Patterns.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-Patterns/

    -- https://package.elm-lang.org/packages/jfmengels/elm-review-unused/latest/NoUnused-Variables/
    , NoUnused.Variables.rule
        |> Rule.ignoreErrorsForFiles
            [ "src/elm/Component/DaisyUi.elm"
            , "src/elm/LocalStorage.elm"
            ]
    , NoUnusedPorts.rule -- https://package.elm-lang.org/packages/sparksp/elm-review-ports/latest/NoUnusedPorts
    , NoUselessSubscriptions.rule -- https://package.elm-lang.org/packages/jfmengels/elm-review-the-elm-architecture/latest/NoUselessSubscriptions
    , Simplify.rule Simplify.defaults -- https://package.elm-lang.org/packages/jfmengels/elm-review-simplify/latest/Simplify/
    , UseCamelCase.rule UseCamelCase.default -- https://package.elm-lang.org/packages/sparksp/elm-review-camelcase/latest/UseCamelCase
    , UseMemoizedLazyLambda.rule -- https://package.elm-lang.org/packages/noredink/elm-review-html-lazy/latest/UseMemoizedLazyLambda/
    ]
        |> List.map
            (Rule.ignoreErrorsForDirectories
                [ "generated/"
                , "lib/"
                , "tests/VerifyExamples"
                ]
            )
