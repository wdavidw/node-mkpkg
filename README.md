
Node.js packages creation as easy as `mkpkg`
--------------------------------------------

Run `mkpkg` and you will be prompted to all the necessary questions to create a new Node.js package. Following Node.js recommandations and community practices, you will end with a project containing all the basic functionnalities to start your new project. Git, CoffeeScript, test engines, code coverage and many other concerns are handled based on your provided answers.

Installation
------------

The prefered method to install `mkpkg` is with [npm]. This module is commonly installed globally. Here's how:

```bash
npm install -g mkpkg
```

Usage
-----

Simply execute `mkpkg` and you will be asked questions to prepare you new project. For power users press escape at any time to see a list of options. Availabe commands are:

*   `[c]reate`  Create your new project (default).
*   `[j]ump`    Jump to an already answered question.
*   `[l]aod`    Load a saved project definition.
*   `[q]uit`    Cancel the project creation and leave.
*   `[r]eset`   Erase previous answers.
*   `[s]ave`    Write this project definition to a file for later usage.
*   `[v]iew`    View previous answers.

Feedback
--------

There is a large place for suggestions and improvements. Feel [new issues][issue] on [github][github].

* [npm]: https://npmjs.org/
* [github]: https://github.com/wdavidw/node-mkpkg
* [issue]: https://github.com/wdavidw/node-mkpkg/issues