import React, { PropsWithChildren, useCallback, useEffect, useState, useRef } from 'react';
import { useMousedown } from 'components/misc/resizable/useMousedown';
import { positionRect } from 'data/content/utils';
import { Popover, PopoverAlign, PopoverPosition } from 'react-tiny-popover';
import { Editor } from 'slate';
import { ReactEditor, useSlate } from 'slate-react';

const offscreenRect = { top: -5000, left: -5000 };

interface Props {
  isOpen: boolean | ((editor: Editor) => boolean);
  content: JSX.Element;
  position?: PopoverPosition;
  reposition?: boolean;
  align?: PopoverAlign;
  relativeTo?: HTMLElement | (() => HTMLElement | undefined);
  style?: React.CSSProperties;
}
export const HoverContainer = (props: PropsWithChildren<Props>) => {
  const editor = useSlate();

  const mousedown = useMousedown();
  const [position, setPosition] = useState(offscreenRect);
  const isOpen = typeof props.isOpen === 'function' ? props.isOpen(editor) : props.isOpen;

  useEffect(() => {
    if (!isOpen) setPosition(offscreenRect);
  }, [isOpen]);

  const preventMouseDown = useCallback(
    (e: React.MouseEvent<HTMLDivElement, MouseEvent>) => e.preventDefault(),
    [],
  );

  const children = <span style={{ ...props.style }}>{props.children}</span>;

  if (!isOpen) return children;

  return (
    <Popover
      isOpen
      reposition={props.reposition}
      contentLocation={(state) => {
        const childRect =
          (props.relativeTo
            ? typeof props.relativeTo === 'function'
              ? props.relativeTo()?.getBoundingClientRect()
              : props.relativeTo.getBoundingClientRect()
            : state.childRect) || state.childRect;

        if (mousedown) return position;

        const newPosition = positionRect(
          {
            ...state,
            position: props.position || 'bottom',
            align: props.align || 'start',
            childRect,
          },
          props.reposition,
          ReactEditor.toDOMNode(editor, editor),
        );

        // setting state in render is bad practice, but react-tiny-popover nudges the popover
        // position even if you don't want it to change.
        if (newPosition !== position) setPosition(newPosition);

        return newPosition;
      }}
      content={
        <div className="hover-container" onMouseDown={preventMouseDown}>
          {props.content}
        </div>
      }
    >
      {children}
    </Popover>
  );
};
HoverContainer.displayName = 'HoverContainer';
