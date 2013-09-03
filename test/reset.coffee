
should = require 'should'
test = require '../lib/test'

describe 'help', ->

  it 'print help if we press esc key', (next) ->
    test [
      (chunk, input) ->
        if /^1\./.test chunk
          input.push 'my-project\n'
          true
      (chunk, input) ->
        if /^2\./.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'r\n'
          true
      (chunk, input) ->
        if /^1\./.test chunk
          input.push '\x1B'
          true
      (chunk, input) ->
        if /^Press \[enter\]/.test chunk
          input.push 'q\n'
          true
    ], (err, out) ->
      next err






