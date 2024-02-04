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
import List
import MultipleAppendToConcat
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeConstructor
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoPrimitiveTypeAlias
import NoRecordAliasConstructor
import NoRecursiveUpdate
import NoRegex
import NoSimpleLetBody
import NoSinglePatternCase
import NoUnnecessaryTrailingUnderscore
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
import NoUselessSubscriptions
import Review.Rule as Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ CognitiveComplexity.rule 8
    , Docs.NoMissing.rule
        { document = onlyExposed
        , from = allModules
        }
    , Docs.ReviewAtDocs.rule
    , Docs.ReviewLinksAndSections.rule
    , Docs.UpToDateReadmeLinks.rule
    , MultipleAppendToConcat.rule MultipleAppendToConcat.ApplyList
    , NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoMissingSubscriptionsCall.rule
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeConstructor.rule
    , NoMissingTypeExpose.rule
    , NoPrematureLetComputation.rule
    , NoPrimitiveTypeAlias.rule
    , NoRecordAliasConstructor.rule
    , NoRecursiveUpdate.rule
    , NoRegex.rule
    , NoSimpleLetBody.rule
    , NoSinglePatternCase.rule NoSinglePatternCase.fixInArgument
    , NoUnnecessaryTrailingUnderscore.rule
    , NoUnsortedCases.rule NoUnsortedCases.defaults
    , NoUnsortedLetDeclarations.rule
        (NoUnsortedLetDeclarations.sortLetDeclarations
            |> NoUnsortedLetDeclarations.alphabetically
        )
    , NoUnsortedRecords.rule
        (NoUnsortedRecords.defaults
            |> NoUnsortedRecords.reportAmbiguousRecordsWithoutFix
        )

    {- Stack overflow whith this rule enabled

       , NoUnsortedTopLevelDeclarations.rule
           (NoUnsortedTopLevelDeclarations.sortTopLevelDeclarations
               |> NoUnsortedTopLevelDeclarations.portsFirst
               |> NoUnsortedTopLevelDeclarations.exposedOrderWithPrivateLast
               |> NoUnsortedTopLevelDeclarations.alphabetically
           )
    -}
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , NoUselessSubscriptions.rule
    , Simplify.rule Simplify.defaults
    ]
        |> List.map
            (Rule.ignoreErrorsForDirectories
                [ "generated/"
                , "lib/"
                , "tests/VerifyExamples"
                ]
            )
