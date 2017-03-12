#! /usr/bin/env node

//
// cli.js
//
// Copyright (c) 2016-2017 Junpei Kawamoto
//
// This software is released under the MIT License.
//
// http://opensource.org/licenses/mit-license.php
//
const {
    comments,
    close
} = require("../lib/scraper");

const argv = require("yargs")
    .usage("Usage: $0 url")
    .demandCommand(1)
    .version()
    .help("h")
    .alias("h", "help")
    .argv;


const url = argv._[0];
console.log(`Getting comments from the video: ${url}`);
comments(url).then((res) => {
    console.log(JSON.stringify(res));
    close();
}).catch((err) => {
    console.error(err);
    close();
});
