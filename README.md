Youtube comment scraper
==========================
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Scraping comments from Youtube.

Build and run
-------

### Build
Run the following two command.

```
$ npm install
$ npm run build
```

### Run

```
$ ./bin/cli.js <url> --delay 30000
```

`<url>` is a Youtube url. `delay` is an optional parameter to specify how long
the program will wait to load all pages. Default value is 30000 msec.
If results do not have all comments, use longer time.

Output is a JSON file and its schema is

```
{
  "url": "the given url",
  "root": "root comment",
  "like": "like score (summation of +1 for like and -1 for dislike)",
  "children": [
    {
      "comment": "reply comment",
      "like": "like score"
    },
    ....
  ]
}
```

License
--------
This software is released under the MIT License, see [LICENSE](LICENSE).
