import React from 'react';
import { onEditModel } from 'components/editing/elements/utils';
import * as ContentModel from 'data/content/model/elements/types';
import { EditorProps } from 'components/editing/elements/interfaces';
import { HoverContainer } from 'components/editing/toolbar/HoverContainer';
import { Resizable } from 'components/misc/resizable/Resizable';
import { CaptionEditor } from 'components/editing/elements/common/settings/CaptionEditor';
import { useElementSelected } from 'data/content/utils';
import { ImagePlaceholder } from 'components/editing/elements/image/block/ImagePlaceholder';
import { ImageSettings } from 'components/editing/elements/image/ImageSettings';
import { Formula } from '../../../common/Formula';
import { FormulaSettings } from './FormulaSettings';

interface Props extends EditorProps<ContentModel.FormulaBlock | ContentModel.FormulaInline> {}
export const FormulaEditor = (props: Props) => {
  const selected = useElementSelected();
  const onEdit = onEditModel(props.model);

  if (props.model.src === undefined)
    return (
      <div {...props.attributes} contentEditable={false}>
        FORMULA PLACEHOLDER
      </div>
    );

  return (
    <div {...props.attributes} contentEditable={false}>
      {props.children}

      <HoverContainer
        style={{ display: 'block' }}
        isOpen={selected}
        align="start"
        position="top"
        content={
          <FormulaSettings
            model={props.model}
            onEdit={onEdit}
            commandContext={props.commandContext}
          />
        }
      >
        <Formula
          style={{ cursor: 'pointer' }}
          type={props.model.type}
          subtype={props.model.subtype}
          src={props.model.src}
        />
      </HoverContainer>
    </div>
  );
};
