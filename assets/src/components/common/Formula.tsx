import React from 'react';
import { MathJaxLatexFormula, MathJaxMathMLFormula } from './MathJaxFormula';

export const Formula: React.FC<{
  type?: string;
  subtype: string;
  src: string;
  style?: Record<string, string>;
}> = ({ type, subtype, src, style }) => {
  switch (subtype) {
    case 'latex':
      return <MathJaxLatexFormula style={style} inline={type === 'formula_inline'} src={src} />;
    case 'mathml':
      return <MathJaxMathMLFormula style={style} inline={type === 'formula_inline'} src={src} />;
    default:
      return <div>TODO - subtype=default</div>;
  }
};

Formula.defaultProps = {
  style: {},
  type: 'formula',
};
