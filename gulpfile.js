//
// gulpfile.js
//
// Copyright (c) 2016-2017 Junpei Kawamoto
//
// This software is released under the MIT License.
//
// http://opensource.org/licenses/mit-license.php
//
const gulp = require("gulp");
const coffee = require("gulp-coffee");
const del = require("del");

const config = {
    src: "src",
    dest: "lib",
}

gulp.task("default", ["build"]);
gulp.task("build", ["lib"]);

gulp.task("clean", () => {
    return del([`${config.bin}/**/*`, `${config.dest}/**/*`]);
});

gulp.task("lib", ["clean"], () => {
    return gulp.src([`${config.src}/*.coffee`, `!${config.src}/cli.coffee`])
        .pipe(coffee())
        .pipe(gulp.dest(config.dest));
});
