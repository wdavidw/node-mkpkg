
unstyle = require './unstyle'

# Fix readline interface
Interface = require('readline').Interface
Interface.prototype.setPrompt = ( (parent) ->
  (prompt, length) ->
    args = Array.prototype.slice.call arguments
    args[1] = unstyle(args[0]).length if not args[1]
    parent.apply @, args
)( Interface.prototype.setPrompt )
