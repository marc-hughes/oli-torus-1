import React, { useCallback } from 'react';
import { EditorProps } from 'components/editing/elements/interfaces';
import * as ContentModel from '../../../../data/content/model/elements/types';
import { useEditModelCallback } from '../utils';
import { InlineEditor } from '../common/settings/InlineEditor';
import { CommandContext } from '../commands/interfaces';
import { insertDescriptionDefinition, insertDescriptionTerm } from './description-list-actions';
import { useSelected, useSlate } from 'slate-react';

type TitleType = ContentModel.Inline | ContentModel.TextBlock;

const TitleEditor: React.FC<{
  title: TitleType[];
  onEdit: (val: TitleType[]) => void;
  commandContext: CommandContext;
}> = ({ title, onEdit, commandContext }) => {
  return (
    <div className="figure-title-editor">
      <InlineEditor
        placeholder="Description List Title"
        allowBlockElements={false}
        commandContext={commandContext}
        content={Array.isArray(title) ? title : []}
        onEdit={onEdit}
      />
    </div>
  );
};

interface Props extends EditorProps<ContentModel.DescriptionList> {}
export const DescriptionListEditorEditor: React.FC<Props> = ({
  model,
  attributes,
  children,
  commandContext,
}) => {
  //
  const onEdit = useEditModelCallback(model);
  const editor = useSlate();
  const selected = useSelected();

  const onAddTerm = useCallback(() => {
    insertDescriptionTerm(editor);
  }, [editor]);
  const onAddDefinition = useCallback(() => {
    insertDescriptionDefinition(editor);
  }, [editor]);

  const onEditTitle = useCallback(
    (val: TitleType[]) => {
      onEdit({
        title: val,
      });
    },
    [onEdit],
  );

  return (
    <div {...attributes} className="description-list-editor">
      <h4 contentEditable={false}>
        <TitleEditor title={model.title} commandContext={commandContext} onEdit={onEditTitle} />
      </h4>

      <dl>{children}</dl>

      {selected && (
        <div contentEditable={false} className="description-list-editor-controls">
          <button className="btn btn-secondary btn-small" onClick={onAddTerm}>
            Add Term
          </button>
          <button className="btn btn-secondary btn-small" onClick={onAddDefinition}>
            Add Definition
          </button>
        </div>
      )}
    </div>
  );
};
