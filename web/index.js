"use strict";

import "./tailwind.css";
require("../src/sass/main.scss");
import { createClient } from "graphql-ws";

const { Elm } = require("../src/elm/Main.elm");
const app = Elm.Main.init();

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
    lazy: false,
    onNonLazyError: (error) => {
        console.error("Error from server", error);
        app.ports.socketStatusReconnecting.send(error);
    },
});

app.ports.createSubscriptions.subscribe(function (params) {
    console.log("Creating subscription:", params);

    (async () => {
        const subscription = client.iterate({
            query: params.query,
        });

        for await (const data of subscription) {
            console.log("Got subscription data", data, "for", params);
            app.ports.gotSubscriptionData.send({
                module: params.module,
                data: data,
            });
        }
    })();
});

app.ports.sendQuery.subscribe(function (params) {
    console.log("Sending query:", params);

    (async () => {
        const subscription = client.iterate({
            query: params.query,
        });

        for await (const data of subscription) {
            console.log("Got query data", data, "for", params);
            app.ports.gotQueryData.send({
                module: params.module,
                data: data,
            });

            break;
        }
    })();
});

app.ports.sendMutation.subscribe(function (params) {
    console.log("Sending mutation:", params);

    (async () => {
        const subscription = client.iterate({
            query: params.query,
        });

        for await (const data of subscription) {
            console.log("Got mutation data", data, "for", params);
            app.ports.gotMutationData.send({
                module: params.module,
                data: data,
            });

            break;
        }
    })();
});

app.ports.setDarkMode.subscribe(function (darkModeActive) {
    localStorage.setItem("darkModeActive", JSON.stringify(darkModeActive));
});

let timeOffset = 0;
app.ports.currentServerTimeReceived.subscribe(function (now) {
    timeOffset = now - new Date().getTime();
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

let lastTime = new Date().getTime() + timeOffset;
const getCurrentTimeInterval = 100;
function getCurrentTime() {
    const now = new Date().getTime() + timeOffset;

    if (Math.floor(now / 1000) !== Math.floor(lastTime / 1000)) {
        app.ports.clockTicked.send(now);
    }

    lastTime = now;

    const timeout = getCurrentTimeInterval - (now % getCurrentTimeInterval);
    setTimeout(getCurrentTime, timeout);
}

getCurrentTime();
