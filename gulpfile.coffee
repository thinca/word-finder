{spawn} = require 'child_process'
fs = require 'fs'

gulp = require 'gulp'
plumber = require 'gulp-plumber'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
sourcemaps = require 'gulp-sourcemaps'
ghPages = require 'gulp-gh-pages'
del = require 'del'


coffeeFiles = './coffee/**/*.coffee'

gulp.task 'coffee', ->
  gulp.src(coffeeFiles)
    .pipe(plumber())
    .pipe(sourcemaps.init())
    .pipe(coffee())
    .pipe(sourcemaps.write('./maps'))
    .pipe(gulp.dest('./js'))

gulp.task 'lint', ->
  gulp.src(coffeeFiles)
    .pipe(plumber())
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())

gulp.task 'clean', (cb) ->
  del(['_site', 'js'], cb)

gulp.task 'fetch_dict', (cb) ->
  if fs.existsSync('./data')
    cb()
  else
    process = spawn 'ruby', ['./tools/get_words.rb'], stdio: 'inherit'
    process.on 'error', console.log
    process.on 'exit', cb

gulp.task 'generate', ['clean', 'fetch_dict', 'coffee'], ->
  gulp.src(['index.html', 'js/*.js', 'data/*'], base: '.')
    .pipe(gulp.dest('_site'))

gulp.task 'deploy', ['generate'], ->
  gulp.src('./_site/**/*')
    .pipe(ghPages())

gulp.task 'watch', ->
  gulp.watch './coffee/**/*.coffee', ['coffee']

gulp.task 'default', ['deploy']
