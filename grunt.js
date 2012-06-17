module.exports = function(grunt) {
  grunt.initConfig({
    lint: {
      files: 'src/js/**/*'
    },
    concat: {
      map: {
        src: ['src/vendor/underscore/underscore.js',
              'src/js/map/utils.js',
              'src/js/map/loader.js'],
        dest: 'public/js/map.js'
      }
    },
    min: {
      map: {
        src: 'public/js/map.js', 
        dest: 'public/js/map.min.js'
      }
    },
    recess: {
      dev: {
        src: ['src/css/style.less'],
        dest: 'public/css/style.css',
        options: {
          compile: true
        }
      },
      prod: {
        src: ['src/css/style.less'],
        dest: 'public/css/style.min.css',
        options: {
          compress: true
        }
      }
    },
    watch: {
      files: 'src/**/*',
      tasks: 'recess:dev concat'
    }
  });

  grunt.loadNpmTasks('grunt-recess');

  grunt.registerTask('prod', 'lint recess:prod concat min');
};
