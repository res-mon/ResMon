"use strict";

import "./tailwind.css";
require("../src/sass/main.scss");

const { Elm } = require("../src/elm/Main.elm");
const app = Elm.Main.init();

require("../lib/js/PortFunnel/PortFunnel.js");
PortFunnel.subscribe(app);
require("../lib/js/PortFunnel/LocalStorage.js");