import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AttractMode } from './components/menu/AttractMode';
import { CreditsPage } from './routes/CreditsPage';
import './App.css';

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AttractMode />} />
        <Route path="/play" element={<AttractMode />} />
        <Route path="/credits" element={<CreditsPage />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;
