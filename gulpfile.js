//
// gulpfile.js
//
// Copyright (c) 2016 Junpei Kawamoto
//
// This software is released under the MIT License.
//
// http://opensource.org/licenses/mit-license.php
//
const gulp = require("gulp");
const coffee = require("gulp-coffee");
const chmod = require("gulp-chmod");
const inject = require("gulp-inject-string");
const del = require("del");

const config = {
    src: "src",
    dest: "lib",
    bin: "bin"
}

gulp.task("default", ["build"]);
gulp.task("build", ["bin", "lib"]);

gulp.task("clean", () => {
    return del([`${config.bin}/**/*`, `${config.dest}/**/*`]);
});

gulp.task("bin", ["clean"], () => {
    return gulp.src(`${config.src}/cli.coffee`)
        .pipe(coffee())
        .pipe(chmod(0x1ed))
        .pipe(inject.prepend("#!/usr/bin/env node\n"))
        .pipe(gulp.dest(config.bin));
});

gulp.task("lib", ["clean"], () => {
    return gulp.src([`${config.src}/*.coffee`, `!${config.src}/cli.coffee`])
        .pipe(coffee())
        .pipe(gulp.dest(config.dest));
});
