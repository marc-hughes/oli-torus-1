import React from 'react';
import { useAuthoringElementContext } from 'components/activities/AuthoringElementProvider';
import { escapeInput, RuleOperator, unescapeInput } from 'data/activities/model/rules';
import { MathLive } from 'components/common/MathLive';

interface State {
  operator: RuleOperator;
  input: string;
}
interface InputProps {
  setState: (s: State) => void;
  state: State;
}
export const MathInput: React.FC<InputProps> = ({ state, setState }) => {
  const { editMode } = useAuthoringElementContext();

  if (typeof state.input != 'string') {
    return null;
  }

  return (
    <div className="mb-2">
      <MathLive
        value={unescapeInput(state.input)}
        options={{
          readOnly: !editMode,
        }}
        onChange={(latex: string) => setState({ input: escapeInput(latex), operator: 'equals' })}
      />
    </div>
  );
};
