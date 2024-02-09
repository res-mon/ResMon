const path = require("path");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = (withDebug) => {
    return {
        entry: "./web/index.js",
        output: {
            path: path.resolve(__dirname, "../webroot"),
            filename: "app-[chunkhash].js",
            publicPath: "/"
        },
        resolve: {
            modules: [
                path.join(__dirname, "../src/elm"),
                path.join(__dirname, "../sass"),
                path.join(__dirname, "../web"),
                "node_modules"
            ],
            extensions: [".elm", ".js"]
        },
        plugins: [
            new HtmlWebpackPlugin({
                template: "./web/index.html",
                favicon: "./static/favicon.ico"
            }),
            new CleanWebpackPlugin()
        ],
        optimization: {
            emitOnErrors: false
        },
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    use: [
                        { loader: "elm-reloader" },
                        {
                            loader: "elm-webpack-loader",
                            options: {
                                debug: withDebug,
                                optimize: false
                            }
                        }
                    ]
                }, {
                    test: /\.(sa|sc|c)ss$/i,
                    use: ["style-loader", "css-loader", {
                        loader: "postcss-loader",
                        options: {
                            postcssOptions: {
                                plugins: [
                                    //require("tailwindcss")("./config/tailwind.config.js"),
                                    require("autoprefixer")
                                ]
                            }
                        }
                    }, "sass-loader"]
                },
                {
                    test: /\.(png|svg|jpg|jpeg|gif)$/i,
                    type: "asset/resource"
                }
            ]
        },
        watchOptions: {
            ignored: ["**/assets/", "**/node_modules", "**/elm-stuff"],
            poll: 1000
        }
    };
};