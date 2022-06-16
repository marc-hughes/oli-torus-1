import { modalActions } from 'actions/modal';
import { createButtonCommandDesc } from 'components/editing/elements/commands/commandFactories';
import { CommandContext } from 'components/editing/elements/commands/interfaces';
import { selectImage } from 'components/editing/elements/image/imageActions';
import { ImageModal } from 'components/editing/elements/image/ImageModal';
import { CommandButton } from 'components/editing/toolbar/buttons/CommandButton';
import { DescriptiveButton } from 'components/editing/toolbar/buttons/DescriptiveButton';
import { Toolbar } from 'components/editing/toolbar/Toolbar';
import React from 'react';
import { Maybe } from 'tsmonad';
import * as ContentModel from 'data/content/model/elements/types';
import { FormulaModal } from './FormulaModal';

type AllFormulaType = ContentModel.FormulaBlock | ContentModel.FormulaInline;
interface EditableProps {
  subtype: string;
  src: string;
}

interface SettingsProps {
  commandContext: CommandContext;
  model: AllFormulaType;
  onEdit: (attrs: Partial<AllFormulaType>) => void;
}
export const FormulaSettings = (props: SettingsProps) => {
  return (
    <Toolbar context={props.commandContext}>
      <Toolbar.Group>
        <EditFormulaButton model={props.model} onEdit={props.onEdit} />
      </Toolbar.Group>
    </Toolbar>
  );
};
interface SelectImageProps {
  model: AllFormulaType;
  onEdit: (attrs: Partial<EditableProps>) => void;
}
const EditFormulaButton = (props: SelectImageProps) => (
  <CommandButton
    description={createButtonCommandDesc({
      icon: 'functions',
      description: 'Edit Formula',
      execute: (_context, _editor, _params) =>
        window.oliDispatch(
          modalActions.display(
            <FormulaModal
              model={props.model}
              onDone={({ src, subtype }: Partial<EditableProps>) => {
                window.oliDispatch(modalActions.dismiss());
                props.onEdit({ src, subtype });
              }}
              onCancel={() => window.oliDispatch(modalActions.dismiss())}
            />,
          ),
        ),
    })}
  />
);
