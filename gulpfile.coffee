config = require('./config.json')
fs = require('fs')
https = require('https')
path = require('path')
gulp = require("gulp")
glob = require("glob")
sass = require("gulp-sass")
replace = require("gulp-replace")
concat = require("gulp-concat")
sourcemaps = require("gulp-sourcemaps")
watch = require('gulp-watch')
webserver = require("gulp-webserver")
coffee = require("gulp-coffee")
sourcemaps = require("gulp-sourcemaps")
changed = require("gulp-changed")
wiredep = require("wiredep").stream
templateCache = require("gulp-angular-templatecache")
inject = require("gulp-inject")
coffeelint = require('gulp-coffeelint')
del = require('del')
vinylPaths = require('vinyl-paths')
runSequence = require('run-sequence')
minifyCss = require('gulp-minify-css')
uglify = require('gulp-uglify')
useref = require('gulp-useref')
rename = require('gulp-rename')
gulpIf = require('gulp-if')
ngAnnotate = require('gulp-ng-annotate')
header = require('gulp-header')

error_handle = (err) ->
    console.error(err)

COMPILE_PATH = "./.compiled"            # Compiled JS and CSS, Images, served by webserver
TEMP_PATH = "./.tmp"                    # hourlynerd dependencies copied over, uncompiled
APP_PATH = "./app"                      # this module's precompiled CS and SASS
BOWER_PATH = "./app/bower_components"   # this module's bower dependencies
DOCS_PATH = './docs'
DIST_PATH = './dist'


paths =
    sass: [
        "./app/modules/**/*.scss"
        "./.tmp/modules/**/*.scss"
    ]
    templates: [
        "./app/modules/**/*.html"
        "./.tmp/modules/**/*.html"
    ]
    coffee: [
        "./app/modules/**/*.coffee"
        "./.tmp/modules/**/*.coffee"
    ]
    images: [
        "./app/modules/**/images/*.+(png|jpg|gif|jpeg)"
        "./.tmp/modules/**/images/*.+(png|jpg|gif|jpeg)"
    ]
    fonts: BOWER_PATH + '/**/*.+(woff|woff2|svg|ttf|eot)'
    hn_assets: BOWER_PATH + '/hn-*/app/modules/**/*.*'


gulp.task('watch', ->
    watch(paths.sass, ->
        runSequence('sass', 'inject', 'bower')
    )
    watch(paths.coffee, ->
        runSequence('coffee', 'inject', 'bower')
    )
    watch(BOWER_PATH, ->
        runSequence('inject', 'bower')
    )
    watch(paths.templates, ->
        runSequence('templates', 'inject', 'bower')
    )
    watch(APP_PATH+'/index.html', ->
        runSequence('inject', 'bower')
    )
    watch(paths.hn_assets, ->
        runSequence('clean:tmp', 'clean:compiled', 'inject', 'inject:version', 'copy_deps', ['coffee', 'sass'])
    )
)

gulp.task "clean:compiled", (cb) ->
    return gulp.src(COMPILE_PATH)
        .pipe(vinylPaths(del))

gulp.task "clean:tmp", (cb) ->
    return gulp.src(TEMP_PATH)
        .pipe(vinylPaths(del))


gulp.task "clean:docs", (cb) ->
    return gulp.src(DOCS_PATH)
        .pipe(vinylPaths(del))


gulp.task "clean:dist", (cb) ->
    return gulp.src(DIST_PATH)
        .pipe(vinylPaths(del))


gulp.task "inject", ->
    target = gulp.src("./app/index.html")
    sources = gulp.src([
        "./.compiled/modules/**/*.css"
        "./.compiled/squire-raw.js"
        "./.compiled/modules/"+config.main_module_name+"/"+config.main_module_name+".module.js"
        "./.compiled/modules/"+config.main_module_name+"/*.provider.js"
        "./.compiled/modules/"+config.main_module_name+"/*.run.js"
        "./.compiled/modules/"+config.main_module_name+"/*.js"
        "./.compiled/modules/**/*.module.js"
        "./.compiled/modules/**/*.provider.js"
        "./.compiled/templates.js"
        "./.compiled/config.js"
        "./.compiled/modules/**/*.run.js"
        "./.compiled/modules/**/*.js"
    ], read: false)

    return target
        .pipe(inject(sources,
            ignorePath: [".compiled", BOWER_PATH]
            transform:  (filepath) ->
                return inject.transform.apply(inject.transform, [filepath])
        ))
        .pipe(gulp.dest(COMPILE_PATH))
        .on "error", error_handle

gulp.task('inject:version', ->
    return gulp.src(COMPILE_PATH + "/index.html")
        .pipe(inject(gulp.src('./bower.json'),
            starttag: '<!-- build_info -->',
            endtag: '<!-- end_build_info -->'
            transform: (filepath, file) ->
                contents = file.contents.toString('utf8')
                data = JSON.parse(contents)
                return "<!-- version: #{data.version} -->"
        ))
        .pipe(gulp.dest(COMPILE_PATH))
        .on "error", error_handle
)

gulp.task "webserver", ->
    return gulp.src([
            COMPILE_PATH
            TEMP_PATH
            APP_PATH
        ])
        .pipe(webserver(
            fallback: 'index.html'
            host: config.dev_server.host
            port: config.dev_server.port
            directoryListing:
                enabled: true
                path: COMPILE_PATH
            middleware: [
                (req, res, next) ->
                    req.url = '/' if req.url  == ''
                    next()
            ]
        ))
        .on "error", error_handle

gulp.task "bower", ->
    return gulp.src(COMPILE_PATH + "/index.html")
        .pipe(wiredep({
            directory: BOWER_PATH
            ignorePath: '../app/'
            exclude: config.bower_exclude
        }))
        .pipe(gulp.dest(COMPILE_PATH))
        .on "error", error_handle


gulp.task "sass", ->
    return gulp.src(paths.sass)
        .pipe(sourcemaps.init())
        .pipe(sass({
            includePaths: [ '.tmp/', 'app/bower_components', 'app' ]
            precision: 8
            onError: (err) ->
                console.log err
        }))
        .pipe(sourcemaps.write())
        .pipe(gulp.dest(COMPILE_PATH + "/modules"))
        .on("error", error_handle)

gulp.task "templates", ->
    return gulp.src(paths.templates)
        .pipe(templateCache("templates.js",
            module: config.app_name
            root: '/modules'
        ))
        .pipe(gulp.dest(COMPILE_PATH))
        .on "error", error_handle

gulp.task "coffee", ->
    return gulp.src(paths.coffee)
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
        .on("error", (err) ->
            console.log(err)
            this.emit('end')
        )
    #    .pipe(sourcemaps.init())
        .pipe(coffee())
    #    .pipe(sourcemaps.write())
        .pipe(ngAnnotate())
        .pipe(gulp.dest(COMPILE_PATH + "/modules"))
        .on "error", error_handle

gulp.task "copy_deps", ->
    return gulp.src(paths.hn_assets, {
            dot: true
            base: BOWER_PATH
        })
        .pipe(rename( (file) ->
            if file.extname != ''

                parts = file.dirname.split('/')
                file.dirname = file.dirname.replace(parts[0] + '/app/', '')
                return file
            else
                return no
        ))
        .pipe(gulp.dest(TEMP_PATH));

copyFonts = ->
    return gulp.src(paths.fonts, {
        dot: true
        base: BOWER_PATH
    }).pipe(rename( (file) ->
        if file.extname != ''
            file.dirname = 'fonts'
            return file
        else
            return no
    ))
gulp.task "copy_fonts", ->
    copyFonts().pipe(gulp.dest(COMPILE_PATH))

gulp.task "copy_squire", ->
    return gulp.src(["./app/bower_components/squire-rte/build/squire-raw.js"], {
            dot: true
            base: "./app/bower_components/squire-rte/build/"
        }).pipe(gulp.dest(COMPILE_PATH))

gulp.task "copy_fonts:dist", ->
    copyFonts().pipe(gulp.dest(DIST_PATH))

gulp.task "add_sass", ->
    return gulp.src(paths.sass)
    .pipe(rename( (file) ->
        if file.extname != ''
            file.dirname = 'css'
            console.log file
            return file
        else
            return no
    )).pipe(gulp.dest(DIST_PATH))


gulp.task "add_banner", ->
    banner = """/**
* @preserve <%= pkg.name %> - <%= pkg.description %>
* @version v<%= pkg.version %>
* @link <%= pkg.homepage %>
* @license <%= pkg.license %>
*
* angular-squire includes squire-rte which is Copyright © by Neil Jenkins. MIT Licensed.
**/

"""
    gulp.src(DIST_PATH+"/**/angular-squire.js")
    .pipe(header(banner, pkg: require(path.join(__dirname, 'bower.json'))))
    .pipe(gulp.dest(DIST_PATH))

gulp.task "package:dist", () ->
    assets = useref.assets()
    return gulp.src(path.join(COMPILE_PATH, "index.html"))
    .pipe(assets)
    .pipe(gulpIf('*.css', minifyCss({
        cache: true
        compatibility: 'colors.opacity' # ie doesnt like rgba values :P
    })))
    .pipe(assets.restore())
    .pipe(useref())
    .pipe(gulp.dest(DIST_PATH))
    .pipe(gulpIf('*.js', uglify()))
    .pipe(gulpIf('*.js', rename({ extname: '.min.js' })))
    .pipe(gulpIf('*.css', rename({ extname: '.min.css' })))
    .pipe(gulp.dest(DIST_PATH))
    .on "error", error_handle

gulp.task "default", (cb) ->
    runSequence(['clean:compiled', 'clean:tmp']
                'copy_deps'
                #'copy_squire'
                'templates'
                ['coffee', 'sass']
                'inject',
                'inject:version'
                'bower'
                'copy_fonts'
                'webserver'
                'watch'
                cb)


gulp.task "build", (cb) ->
    runSequence(['clean:dist', 'clean:compiled', 'clean:tmp']
                'copy_deps'
           #     'copy_squire'
                'templates'
                ['coffee', 'sass']
                'inject',
                'inject:version'
                'bower'
                'copy_fonts:dist'
                'package:dist'
                'add_sass'
                'add_banner')
