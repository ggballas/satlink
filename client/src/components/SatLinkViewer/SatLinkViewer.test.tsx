import React from 'react';
import ReactDOM from 'react-dom';
import SatLinkViewer from './SatLinkViewer';

it('It should mount', () => {
  const div = document.createElement('div');
  ReactDOM.render(<SatLinkViewer />, div);
  ReactDOM.unmountComponentAtNode(div);
});