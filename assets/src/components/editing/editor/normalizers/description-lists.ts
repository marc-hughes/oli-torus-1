import { Transforms, Path, Editor, Element, Text, Ancestor } from 'slate';
import { Model } from 'data/content/model/elements/factories';
import { ModelElement } from 'data/content/model/elements/types';
import { FormattedText } from 'data/content/model/text';
import { schema } from 'data/content/model/schema';

export const normalize = (
  editor: Editor,
  node: ModelElement | FormattedText,
  path: Path,
): boolean => {
  return normalizeParent(editor, node, path) || normalizeChildren(editor, node, path);
};

const isValidDL = (parent: Ancestor) => {
  if (Editor.isEditor(parent)) {
    return false;
  }
  if (!Element.isElement(parent)) {
    return false;
  }
  if (parent.type != 'dl') {
    return false;
  }
  return true;
};

const normalizeChildren = (
  editor: Editor,
  node: ModelElement | FormattedText,
  path: Path,
): boolean => {
  // A bare DT or DD should get wrapped up in a DL
  if ('type' in node && (node.type == 'dt' || node.type == 'dd')) {
    const [parent] = Editor.parent(editor, path);
    if (!isValidDL(parent)) {
      Transforms.wrapNodes(editor, Model.dl([]), { at: path });
      return true;
    }
  }

  return false;
};

const normalizeParent = (
  editor: Editor,
  node: ModelElement | FormattedText,
  path: Path,
): boolean => {
  const [parent] = Editor.parent(editor, path);
  if (Element.isElement(parent)) {
    const config = schema[parent.type];
    if (parent.type == 'dl') {
      if (Text.isText(node)) {
        Transforms.wrapNodes(editor, Model.dt(), { at: path });
        console.warn('Normalizing content: Wrapping text in description-list with list item');
        return true;
      }
      if (Element.isElement(node) && !config.validChildren[node.type]) {
        Transforms.setNodes(editor, { type: 'li' }, { at: path });
        console.warn('Normalizing content: Changing node in description-list to list item type');
        return true;
      }
    }
  }
  return false;
};
