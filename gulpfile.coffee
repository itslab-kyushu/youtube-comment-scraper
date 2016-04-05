gulp = require "gulp"
coffee = require "gulp-coffee"
chmod = require "gulp-chmod"
inject = require "gulp-inject-string"
del = require "del"

gulp.task "clean", ->
  del ["./bin/**/*", "./lib/**/*"]


gulp.task "bin", ["clean"], ->
  gulp.src "./src/cli.coffee"
    .pipe coffee()
    .pipe chmod 755
    .pipe inject.prepend "#!/usr/bin/env node\n"
    .pipe gulp.dest "./bin/"


gulp.task "lib", ["clean"], ->
  gulp.src "./src/scraper.coffee"
    .pipe coffee()
    .pipe gulp.dest "./lib/"


gulp.task "build", ["bin", "lib"]


gulp.task "default", ["build"]
