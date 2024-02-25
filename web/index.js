"use strict";

import "./tailwind.css";
require("../src/sass/main.scss");
import { createClient } from "graphql-ws";

const client = createClient({
    url:
        (window.location.protocol === "http:" ? "ws" : "wss") +
        "://" +
        window.location.host +
        "/api",
    keepAlive: 10000,
    retryAttempts: 180,
    retryWait: (attempt) =>
        new Promise((resolve) =>
            setTimeout(
                resolve,
                Math.random() * 1000 + Math.min(750 * 1.1 ** attempt, 10000)
            )
        ),
    shouldRetry: () => true,
});

const { Elm } = require("../src/elm/Main.elm");
const app = Elm.Main.init();

app.ports.createSubscriptions.subscribe(function (subscription) {
    console.log("Creating subscription:", subscription);

    (async () => {
        const subscription = client.iterate({
            query: "subscription{workClock{activity{active}}}",
        });

        for await (const event of subscription) {
            console.log("Got subscription data", event);
            app.ports.gotSubscriptionData.send(event);
        }
    })();
});

app.ports.setDarkMode.subscribe(function (darkModeActive) {
    localStorage.setItem("darkModeActive", JSON.stringify(darkModeActive));
});

require("../lib/js/PortFunnel/PortFunnel.js");
PortFunnel.subscribe(app);
require("../lib/js/PortFunnel/LocalStorage.js");

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

client.on("connected", () => {
    console.log("Connected to server");
    app.ports.socketStatusConnected.send(null);
});

client.on("error", (error) => {
    console.error("Error from server", error);
    app.ports.socketStatusReconnecting.send(error);
});
