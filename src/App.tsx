import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { LandingPage } from './routes/LandingPage';
import { PlayPage } from './routes/PlayPage';
import './App.css';

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/play" element={<PlayPage />} />
        <Route path="/credits" element={<LandingPage />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;
