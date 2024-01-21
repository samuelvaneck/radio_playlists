module.exports = {
    plugins: [
        require("tailwindcss")("./tailwind.config.js"),
        require('postcss-import'),
        require('autoprefixer'),
        require("postcss-nested"),
        require("postcss-flexbugs-fixes")
    ],
}
