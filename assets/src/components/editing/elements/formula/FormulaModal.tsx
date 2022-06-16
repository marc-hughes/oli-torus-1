import { FullScreenModal } from 'components/editing/toolbar/FullScreenModal';
import React, { Suspense, useState } from 'react';
import * as ContentModel from 'data/content/model/elements/types';
import * as monaco from 'monaco-editor';
import { Formula } from '../../../common/Formula';
import { isDarkMode } from '../../../../utils/browser';

const MonacoEditor = React.lazy(() => import('@uiw/react-monacoeditor'));

type AllFormulaType = ContentModel.FormulaBlock | ContentModel.FormulaInline;

interface ModalProps {
  onDone: (x: any) => void;
  onCancel: () => void;
  model: AllFormulaType;
}

const getToolbarClass = (buttonType: string, activeType: string) =>
  buttonType === activeType ? 'language-active' : 'language';

export const FormulaModal = ({ onDone, onCancel, model }: ModalProps) => {
  const [src, setSrc] = useState(model.src);
  const [subtype, setSubtype] = useState(model.subtype);

  const onClickSubtype = React.useCallback(
    (newSubType: ContentModel.FormulaSubTypes) => (_event: any) => {
      setSubtype(newSubType);
    },
    [subtype],
  );

  const editorDidMount = (e: monaco.editor.IStandaloneCodeEditor) => {
    e.layout({
      width: 600,
      height: 300,
    });
  };

  return (
    <FullScreenModal onCancel={(_e) => onCancel()} onDone={() => onDone({ src, subtype })}>
      <div className="formula-editor">
        <h3 className="mb-2">Formula Editor</h3>
        <div className="split-editor">
          <div className="editor">
            <div className="toolbar">
              <button
                onClick={onClickSubtype('latex')}
                className={getToolbarClass('latex', subtype)}
              >
                Latex
              </button>
              <button
                onClick={onClickSubtype('mathml')}
                className={getToolbarClass('mathml', subtype)}
              >
                MathML
              </button>
              <button
                onClick={onClickSubtype('richtext')}
                className={getToolbarClass('richtext', subtype)}
              >
                Richtext
              </button>
            </div>

            <Suspense fallback={<div>Loading...</div>}>
              <MonacoEditor
                value={model.src}
                language="xml"
                key={subtype}
                options={{
                  tabSize: 2,
                  scrollBeyondLastLine: false,
                  minimap: { enabled: false },
                  theme: isDarkMode() ? 'vs-dark' : 'vs-light',
                }}
                onChange={setSrc}
                editorDidMount={editorDidMount}
              />
            </Suspense>
          </div>
          <div className="preview">
            <h4>Preview</h4>
            <Formula src={src} subtype={subtype} />
          </div>
        </div>
      </div>
    </FullScreenModal>
  );
};
