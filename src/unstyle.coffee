
module.exports = (text) -> text.replace /\x1b.*?m/g, ''
