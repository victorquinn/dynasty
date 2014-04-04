module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        expand: true
        cwd: 'src/'
        src: ['**/*.coffee']
        dest: 'lib/'
        ext: '.js'
      compileTests:
        files: [
          'test/test.dynasty.js': ['test/src/**/*.coffee']
        ]
    coffeelint:
      app: ['src/**/*.coffee']
      options:
        max_line_length:
          level: "ignore"
    shell:
      publish:
        options:
          stdout: true
        command: 'npm publish'
    simplemocha:
      options:
        globals: ['should']
        timeout: 300
        ignoreLeaks: false
        ui: 'bdd'
        reporter: 'spec'
      all:
        src: ['test/*.js']
    watch:
      files: ['Gruntfile.coffee', 'src/**/*.coffee', 'test/src/**/*.coffee']
      tasks: ['coffeelint', 'coffee', 'simplemocha']

  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-shell'

  grunt.registerTask 'test', ['coffee', 'simplemocha']
  grunt.registerTask 'publish', ['coffee', 'shell:publish']
  grunt.registerTask 'default', ['watch']
