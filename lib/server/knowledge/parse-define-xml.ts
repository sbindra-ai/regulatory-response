import { XMLParser } from "fast-xml-parser"

type DefineXmlNode = Record<string, unknown>

export type DefineDatasetVariable = {
  name: string
  label: string
}

export type DefineDataset = {
  name: string
  label: string
  structure: string
  className: string | null
  leaf: string | null
  variables: DefineDatasetVariable[]
}

const parser = new XMLParser({
  attributeNamePrefix: "",
  ignoreAttributes: false,
  parseTagValue: false,
  removeNSPrefix: true,
  trimValues: true,
})

function asArray<T>(value: T | T[] | undefined): T[] {
  if (!value) {
    return []
  }

  return Array.isArray(value) ? value : [value]
}

function getTranslatedText(node: unknown): string {
  if (!node || typeof node !== "object") {
    return ""
  }

  const translatedText = (node as DefineXmlNode).TranslatedText

  if (typeof translatedText === "string") {
    return translatedText
  }

  if (Array.isArray(translatedText)) {
    return translatedText.find((value): value is string => typeof value === "string") ?? ""
  }

  if (translatedText && typeof translatedText === "object") {
    const textValue = (translatedText as DefineXmlNode)["#text"]

    return typeof textValue === "string" ? textValue : ""
  }

  return ""
}

export function parseDefineXml(xml: string): DefineDataset[] {
  const parsed = parser.parse(xml) as DefineXmlNode
  const metaDataVersion = (((parsed.ODM as DefineXmlNode | undefined)?.Study as DefineXmlNode | undefined)
    ?.MetaDataVersion ?? {}) as DefineXmlNode

  const itemDefs = new Map(
    asArray(metaDataVersion.ItemDef as DefineXmlNode[] | DefineXmlNode | undefined).map((itemDef) => [
      String(itemDef.OID),
      itemDef,
    ]),
  )

  return asArray(metaDataVersion.ItemGroupDef as DefineXmlNode[] | DefineXmlNode | undefined)
    .filter((itemGroupDef) => String(itemGroupDef.Purpose ?? "") === "Analysis")
    .filter((itemGroupDef) => String(itemGroupDef.Name ?? "").startsWith("AD"))
    .map((itemGroupDef) => {
      const variables = asArray(itemGroupDef.ItemRef as DefineXmlNode[] | DefineXmlNode | undefined).map((itemRef) => {
        const itemDef = itemDefs.get(String(itemRef.ItemOID))

        return {
          name: String(itemDef?.Name ?? itemRef.ItemOID ?? ""),
          label: getTranslatedText(itemDef?.Description),
        }
      })

      const leaf = asArray(itemGroupDef.leaf as DefineXmlNode[] | DefineXmlNode | undefined)[0]

      return {
        name: String(itemGroupDef.Name ?? ""),
        label: getTranslatedText(itemGroupDef.Description),
        structure: String(itemGroupDef.Structure ?? ""),
        className: typeof itemGroupDef.Class === "string" ? itemGroupDef.Class : null,
        leaf: typeof leaf?.href === "string" ? leaf.href : null,
        variables,
      }
    })
}
