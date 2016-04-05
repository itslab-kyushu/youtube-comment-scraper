Youtube comment scraper
==========================
[![npm version](https://badge.fury.io/js/youtube-comment-scraper.svg)](https://badge.fury.io/js/youtube-comment-scraper)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Scraping comments from Youtube.

Install
----------
```sh
$ npm install -g youtube-comment-scraper
```

Usage
-------

```
Usage: scraper url [options]

        url
                URL for a Youtube video page

        --help, -h
                Displays help information about this script

        --version
                Displays version info

        --delay, -d
                Wait time for loading all pages. (default: 30000)
```

Method
---------
```js
var scraper = require("youtube-comment-scraper");
```

### `scraper(url, [delay])`
Scraping a given Youtube page and return a set of comments.

- Args:
  - url: URL of the target page.
  - delay: Wait time for loading all comment. (Default: 30000msec)
- Returns:
 Promise object. Use "then" to recieve results.

### example
```js
scraper(some_url, 50000).then(function(res) {
  return console.log(JSON.stringify({
    url: some_url,
    comments: res
  }));
});
```

For developers
-----------------

### Build
Run the following two command.

```sh
$ npm install
$ npm run build
```

### Run

```sh
$ ./bin/cli.js <url> --delay 30000
```

`<url>` is a Youtube url. `delay` is an optional parameter to specify how long
the program will wait to load all pages. Default value is 30000 msec.
If results do not have all comments, use longer time.

Output is a JSON file and its schema is

```json
{
  "url": "the given url",
  "comments": [
    {
      "root": "root comment",
      "like": "like score (summation of +1 for like and -1 for dislike)",
      "children": [
        {
          "comment": "reply comment",
          "like": "like score"
        },
        ...
      ]
    },
    ...
  ]
}
```

License
--------
This software is released under the MIT License, see [LICENSE](LICENSE).
