const { merge } = require("webpack-merge");
const common = require("./webpack.common.js");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");

const prod = {
    mode: "production",
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin(),
            new CssMinimizerPlugin()
        ]
    },
    plugins: [
        new CopyWebpackPlugin({
            patterns: [{ from: "static" }]
        }),
        new MiniCssExtractPlugin({
            filename: "app-[chunkhash].css"
        })
    ],
    module: {
        rules: [
            {
                test: /\.elm$/,
                use: {
                    loader: "elm-webpack-loader",
                    options: {
                        optimize: true
                    }
                }
            },
            {
                test: /\.(sa|sc|c)ss$/i,
                use: [
                    MiniCssExtractPlugin.loader,
                    "css-loader",
                    {
                        loader: "postcss-loader",
                        options: {
                            postcssOptions: {
                                plugins: [
                                    //require("tailwindcss")("./config/tailwind.config.js"),
                                    require("autoprefixer")
                                ]
                            }
                        }
                    }, "sass-loader"
                ]
            }
        ]
    }
};

module.exports = merge(common(false), prod);
