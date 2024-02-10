"use strict";

import "./tailwind.css";
require("../src/sass/main.scss");

const { Elm } = require("../src/elm/Main.elm");
const app = Elm.Main.init();

if (localStorage.getItem("darkModeActive")) {
    app.ports.darkModeChanged.send(
        JSON.parse(localStorage.getItem("darkModeActive"))
    );
} else {
    const darkModeActive = !!(
        window.matchMedia &&
        window.matchMedia("(prefers-color-scheme: dark)").matches
    );
    app.ports.darkModeChanged.send(darkModeActive);
}

if (window.matchMedia) {
    window
        .matchMedia("(prefers-color-scheme: dark)")
        .addEventListener("change", (event) => {
            if (localStorage.getItem("darkModeActive")) return;

            app.ports.darkModeChanged.send(event.matches);
        });
}

app.ports.setDarkMode.subscribe(function (darkModeActive) {
    localStorage.setItem("darkModeActive", JSON.stringify(darkModeActive));
});

require("../lib/js/PortFunnel/PortFunnel.js");
PortFunnel.subscribe(app);
require("../lib/js/PortFunnel/LocalStorage.js");
