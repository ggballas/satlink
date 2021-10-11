import React from 'react';
import ReactDOM from 'react-dom';
import TwitterAccountConnection from './TwitterAccountConnection';

it('It should mount', () => {
  const div = document.createElement('div');
  ReactDOM.render(<TwitterAccountConnection />, div);
  ReactDOM.unmountComponentAtNode(div);
});