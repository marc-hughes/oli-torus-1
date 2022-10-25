import { Transforms, Path, Editor, Element, Text } from 'slate';
import { Model } from 'data/content/model/elements/factories';
import { ModelElement } from 'data/content/model/elements/types';
import { FormattedText } from 'data/content/model/text';
import { schema } from 'data/content/model/schema';

const listTypes = [
  { list: ['ul', 'ol'], children: ['li'], defaultWrapper: Model.li },
  { list: ['dl'], children: ['dt', 'dd'], defaultWrapper: Model.dt },
];

export const normalize = (
  editor: Editor,
  node: ModelElement | FormattedText,
  path: Path,
): boolean => {
  for (const listConfig of listTypes) {
    if (
      normalizeList(
        editor,
        node,
        path,
        listConfig.list,
        listConfig.children,
        listConfig.defaultWrapper,
      )
    ) {
      return true;
    }
  }

  return false;
};

const normalizeList = (
  editor: Editor,
  node: ModelElement | FormattedText,
  path: Path,
  listTypes: ('ol' | 'ul' | 'dl')[],
  childrenTypes: ('li' | 'dt' | 'dd')[],
  defaultChildWrapper: () => ModelElement,
): boolean => {
  const [parent] = Editor.parent(editor, path);
  if (Element.isElement(parent)) {
    const config = schema[parent.type];
    if (listTypes.includes(parent.type)) {
      if (Text.isText(node)) {
        Transforms.wrapNodes(editor, defaultChildWrapper(), { at: path });
        console.warn('Normalizing content: Wrapping text in list with list item');
        return true;
      }
      if (Element.isElement(node) && !config.validChildren[node.type]) {
        Transforms.setNodes(editor, { type: childrenTypes[0] }, { at: path });
        console.warn('Normalizing content: Changing node in list to list item type');
        return true;
      }
    }
  }
  return false;
};
