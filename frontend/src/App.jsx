import React from "react";
import Home from "./components/home";

import "./App.css";

function App() {
  console.log("REACT_APP_API_URL:", process.env.REACT_APP_API_URL);
  return (
    <div className="container">
      <Home />
    </div>
  );
}

export default App;
