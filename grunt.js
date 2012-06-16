module.exports = function(grunt) {
  grunt.initConfig({
    recess: {
      dev: {
        src: ['public/css/style.less'],
        dest: 'public/css/style.css',
        options: {
          compile: true
        }
      },
      prod: {
        src: ['public/css/style.less'],
        dest: 'public/css/style.css',
        options: {
          compress: true
        }
      }
    },
    lint: {
      files: 'public/js/**/*'
    },
    watch: {
      files: 'public/**/*.less',
      tasks: 'less:dev'
    }
  });

  grunt.loadNpmTasks('grunt-recess');

  grunt.registerTask('prod', 'recess:prod');
};
