
should = require 'should'
fs = require 'fs'
{exec} = require 'child_process'
test = require '../lib/test'

options = [
  (chunk, input) ->
    if /^\d+\.  Project Name/.test chunk
      input.push 'my-project\n'
      true
  (chunk, input) ->
    if /^\d+\.  Project Description/.test chunk
      input.push 'This is my project\n'
      true
  (chunk, input) ->
    if /^\d+\.  Project location/.test chunk
      input.push '/tmp/my-project\n'
      true
  (chunk, input) ->
    if /^\d+\.  Is this a GIT repository/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\.  GitHub URL/.test chunk
      input.push 'http://www.github.com/wdavidw/my-project\n'
      true
  (chunk, input) ->
    if /^\d+\.  Create license file/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\.  Choose a license or press enter/.test chunk
      input.push 'mit\n'
      true
  (chunk, input) ->
    if /^\d+\.  Create changelog file/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\.  Are you testing your code/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\. Which testing tool are you using?/.test chunk
      input.push 'mocha\n'
      true
  (chunk, input) ->
    if /^\d+\. Are you using code coverage/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\. Which covering tool are you using?/.test chunk
      input.push 'istanbul\n'
      true
  (chunk, input) ->
    if /^\d+\. List of dependencies/.test chunk
      input.push 'csv\n'
      true
  (chunk, input) ->
    if /^\d+\. List of development dependencies/.test chunk
      input.push 'should\n'
      true
  (chunk, input) ->
    if /^\d+\. List of optional dependencies/.test chunk
      input.push '\n'
      true
  (chunk, input) ->
    if /^\d+\. Are you planning to use coffeescript/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\. Create a sample folder/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\. Sample location/.test chunk
      input.push '\n'
      true
  (chunk, input) ->
    if /^\d+\. Do you wish to test against travis?/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\. Wish NodeJs version for Travis/.test chunk
      input.push '\n'
      true
  (chunk, input) ->
    if /^\d+\. Do you plan to write documentation?/.test chunk
      input.push 'yes\n'
      true
  (chunk, input) ->
    if /^\d+\. Inside a folder or a git branch?/.test chunk
      input.push 'folder\n'
      true
  (chunk, input) ->
    if /^\d+\. Folder location/.test chunk
      input.push '\n'
      true
]

describe 'create', ->

  beforeEach (next) ->
    exec 'rm -rf /tmp/my-project', (err) ->
      next err

  it 'init git and create an .gitignore file', (next) ->
    @timeout 0
    test options, (err) ->
      fs.exists '/tmp/my-project', (exists) ->
        exists.should.be.ok
        fs.readFile '/tmp/my-project/.gitignore', 'ascii', (err, content) ->
          return next err if err
          content.should.eql """
          .*
          /node_modules
          !.travis.yml
          !.gitignore
          """
          next()

  it 'create a package declaration file', (next) ->
    test options, (err) ->
      fs.readFile '/tmp/my-project/package.json', 'ascii', (err, content) ->
        return next err if err
        content.should.eql """
        {
            "name": "my-project",
            "repository": {
                "type": "git",
                "url": "http://www.github.com/wdavidw/my-project"
            },
            "dependencies": {
                "csv": "latest"
            },
            "devDependencies": {},
            "optionalDependencies": {}
        }
        """
        next()

  it 'create a coffee file', (next) ->
    test options, (err) ->
      fs.readFile '/tmp/my-project/src/index.coffee', 'ascii', (err, content) ->
        return next err if err
        content.should.eql """

        module.exports = (callback) ->
          process.setImmediate ->
            callback null, 'Hello world'

        """
        next()

  it 'create a js file', (next) ->
    test options, (err) ->
      fs.readFile '/tmp/my-project/lib/index.js', 'ascii', (err, content) ->
        return next err if err
        content.should.eql """

        module.exports = function(callback) {
          return process.setImmediate(function() {
            return callback(null, 'Hello world');
          });
        };

        """
        next()

  it 'prepare a coffee test', (next) ->
    test options, (err) ->
      fs.readFile '/tmp/my-project/test/index.coffee', 'ascii', (err, content) ->
        return next err if err
        content.should.eql """
        should = require 'should'
        index = if process.env['MY_PROJECT_COV'] then require '../lib-cov' else require '../lib'

        describe 'my-project', ->

          it 'pass hello world', (next) ->
            index (err, value) ->
              return next err if err
              value.should.eql 'Hello world'
              next()
        """
        next()

  it 'prepare a js test', (next) ->
    staged = options[15]
    options[15] = (chunk, input) ->
      if /^\d+\. Are you planning to use coffeescript/.test chunk
        input.push 'no\n'
        true
    test options, (err) ->
      fs.readFile '/tmp/my-project/test/index.js', 'ascii', (err, content) ->
        return next err if err
        content.should.eql """
        var should = require('should');
        var index = process.env['MY_PROJECT_COV'] ? require('../lib-cov') : require('../lib');

        describe('my-project', function() {
          return it('pass hello world', function(next) {
            return index(function(err, value) {
              if (err) {
                return next(err);
              }
              value.should.eql('Hello world');
              return next();
            });
          });
        });
        """
        options[15] = staged
        next()


