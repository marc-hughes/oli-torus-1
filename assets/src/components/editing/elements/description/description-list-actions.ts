import { Editor, Transforms } from 'slate';
import { Model } from '../../../../data/content/model/elements/factories';
import {
  DescriptionListDefinition,
  DescriptionListTerm,
} from '../../../../data/content/model/elements/types';
import { SlateEditor } from '../../../../data/content/model/slate';
import { createButtonCommandDesc } from '../commands/commandFactories';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const insertDescriptionListCommand = createButtonCommandDesc({
  icon: 'view_list',
  description: 'Description List',

  execute: (context, editor: Editor) => {
    insertDescriptionList(editor);
  },
});

export const insertDescriptionList = (editor: SlateEditor) => {
  const at = editor.selection as any;
  const list = Model.dl();
  Transforms.insertNodes(editor, list, { at });
};

const appendListItem = (
  editor: SlateEditor,
  element: DescriptionListTerm | DescriptionListDefinition,
) => {
  const at = editor.selection;
  if (!at) return;
  console.info(at);

  Transforms.insertNodes(editor, element, { at });
};

export const appendDescriptionTerm = (editor: SlateEditor) => {
  appendListItem(editor, Model.dt());
};

export const appendDescriptionDefinition = (editor: SlateEditor) => {
  appendListItem(editor, Model.dd());
};
