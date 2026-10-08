import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import WhySolar from "./pages/WhySolar";
import Projects from "./pages/Projects";
import Calculator from "./pages/Calculator";
import Contact from "./pages/Contact";
import AdminInbox from "./pages/AdminInbox";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/why-solar" element={<WhySolar />} />
        <Route path="/projects" element={<Projects />} />
        <Route path="/calculator" element={<Calculator />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/admin/inbox" element={<AdminInbox />} />
        <Route path="*" element={<Home />} />
      </Routes>
    </BrowserRouter>
  );
}
