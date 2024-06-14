import React from "react";
import { createRoot } from 'react-dom/client';
import App from "./watch_ui";

const root = createRoot(document.getElementById('phx-hero'));
root.render(<App />);
