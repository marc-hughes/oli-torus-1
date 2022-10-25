import React, { MouseEventHandler, ReactNode } from 'react';
import * as ContentModel from 'data/content/model/elements/types';
import { HtmlContentModelRenderer } from '../../data/content/writers/renderer';
import { WriterContext } from '../../data/content/writers/context';

export const DescriptionList: React.FC<{
  description: ContentModel.DescriptionList;
  context: WriterContext;
  children: ReactNode;
  onClick?: MouseEventHandler<HTMLDivElement>;
}> = ({ description, children, onClick, context }) => {
  return (
    <>
      <h4>
        <HtmlContentModelRenderer context={context} content={description.title} />
      </h4>
      <dl>{children}</dl>
    </>
  );
};
