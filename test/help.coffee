
should = require 'should'
test = require '../lib/test'

describe 'help', ->

  it 'print help if we press esc key', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ], (err, out) ->
      return next err if err
      out.should.eql """
      Let's create our new Node.js project.
      At any point in time, press [esc] to view the help.
      \u001b[1G\u001b[0J1.  Project Name: 
      [c]reate  Create your new project (default).
      [j]ump    Jump to an already answered question.
      [l]aod    Load a saved project definition.
      [q]uit    Cancel the project creation and leave.
      [r]eset   Erase previous answers.
      [s]ave    Write this project definition to a file for later usage.
      [v]iew    View previous answers.

      Press [enter] to start/resume your project creation or choose one of the command above
      """.replace /\n/g, '\r\n'
      next()






