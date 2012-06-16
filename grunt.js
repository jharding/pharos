module.exports = function(grunt) {
  grunt.initConfig({
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
        dest: 'public/css/style.css',
        options: {
          compress: true
        }
      }
    },
    lint: {
      files: 'src/js/**/*'
    },
    watch: {
      files: 'src/**/*.less',
      tasks: 'recess:dev'
    }
  });

  grunt.loadNpmTasks('grunt-recess');

  grunt.registerTask('prod', 'recess:prod');
};
