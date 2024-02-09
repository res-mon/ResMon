import * as generate from "./generate";
import {
    GroupedDeclarations,
    RecognizedDeclaration,
} from "../types";
import { DocumentationGenerator } from "../docs";
import { fixClass, toElmName } from "../helpers";



// PUBLIC INTERFACE


export function generateElmModule(moduleNamePrefix: string, blocksByClass: GroupedDeclarations, docs: DocumentationGenerator): string {
    const unrecognized = extractUnrecognized(blocksByClass);
    const sortedClasses = Array.from([...blocksByClass.recognized.keys(), ...unrecognized.keys()]).sort();
    const definedNames = [...sortedClasses];
    const moduleName = `${moduleNamePrefix}.Classes`

    return [
        generate.elmModuleHeader({
            moduleName,
            exposing: docs.utilitiesExposing(definedNames),
            imports: [
                generate.singleLine(`import ${moduleNamePrefix}.Utilities as Tw`),
                generate.singleLine("import Css"),
            ],
            moduleDocs: docs.utilitiesModuleDocs(definedNames),
        }),
        elmRecognizedToFunctions(blocksByClass.recognized, docs),
        elmUnrecognizedToFunctions(unrecognized, docs),
    ].join("");
}


// PRIVATE INTERFACE

function extractUnrecognized(blocksByClass: GroupedDeclarations): Map<string, string> {
    const unrecognized = new Map<string, string>();
    const splitRegex = new RegExp("[\\s,>\\(\\)\\[\\],:^$=\\*|#+~]", "g");

    blocksByClass.unrecognized.forEach(declaration => {
        const parts = declaration.selector.split(splitRegex);
        parts.forEach(part => {
            if(!part || part[0] === '"' || part[0] === "'") return;

            const classNames = part.split(".");
            if(classNames.length === 1) return;

            classNames.forEach(className => {
                if(!className) return;

                const elmDeclName = toElmName(fixClass(className));
                if(blocksByClass.recognized.has(elmDeclName)) return;

                unrecognized.set(elmDeclName, className);
            });
        });
    });

    return unrecognized;
}

function elmUnrecognizedToFunctions(unrecognizedBlocks: Map<string, string>, docs: DocumentationGenerator): string {
    let body = "";
    Array.from(unrecognizedBlocks.keys()).sort().forEach(elmClassName => {
        body = body + elmUnrecognizedFunction(elmClassName, unrecognizedBlocks.get(elmClassName), docs);
    });
    return body;
}

function elmRecognizedToFunctions(
    recognizedBlocksByClass: Map<string, RecognizedDeclaration>,
    docs: DocumentationGenerator,
): string {
    let body = "";
    Array.from(recognizedBlocksByClass.keys()).sort().forEach(elmClassName => {
        body = body + elmRecognizedFunction(elmClassName, recognizedBlocksByClass.get(elmClassName), docs);
    });
    return body;
}

function elmRecognizedFunction(
    elmClassName: string,
    propertiesBlock: RecognizedDeclaration,
    docs: DocumentationGenerator,
): string {
    return `
${docs.classesWithUtilityDefinition(elmClassName, propertiesBlock)}
${elmClassName} : ( List Css.Style, List String )
${elmClassName} =
    ( [ Tw.${elmClassName} ]
    , [ ${JSON.stringify(propertiesBlock.originalClassName)} ]
    )
`;
}

function elmUnrecognizedFunction(
    elmClassName: string,
    originalClassName: string,
    docs: DocumentationGenerator,
): string {
    return `
${docs.classesWithoutUtilityDefinition(elmClassName, originalClassName)}
${elmClassName} : ( List Css.Style, List String )
${elmClassName} =
    ( [], [ ${JSON.stringify(originalClassName)} ] )
`;
}