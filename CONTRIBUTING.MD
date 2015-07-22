# Contributing
## General Naming Guidelines
In the formatting data of posts and other information (the `---` block at the top of the file), naming conventions matter!

Feel free to use any sane way to write `title:` values, but `name:` and `author:` values **NEED** to be
all lowercase with no spaces or special characters besides `-`.  i.e. only `a-z` and `-`.

This all lowercase, no space naming convention is **also** required for filenames!

### File Formats
All of these `.md` files you are creating are slightly modified markdown files.
There is a YAML header at the top, which looks like:
```
---
title: example markdown file
name: git
---
```

Everything below the header is evaluated as a pure markdown file; so everything is markdown after the `---` header

### Add an event
To create an event, consider the following:

* create a unique file in the `_events` folder
* add the image poster to `images/events` with a unique filename
* put the filename (only the filename, not any of the path) in the `image:` value of the markdown file
* put a 100x100 image in the `images/events/thumb` folder with the same name as the event poster
* make sure your date follows the format of `2015-01-31 17:00:00`

example event: `_events/example.md`
```
---
title: example event
date: 2015-01-31 17:00:00
image: default.jpg (can be png also)
---
event message here.  this can be blank, a senctence long, or a full essay.
just remember that everything below the --- is a markdown file.
```


### Add a RDJ bio
To create a rdj bio, you need do to the following things:

* create a file in the `_rdjs` directory called `[artist].md`.
* add their logo to `images/rdj` directory as `[artist].png` (optional, and preferred all-white)
* fill out the file.  use any other existing file as a guideline for yours.
* make sure you put their soundcloud id in the `soundcloud:` value

### Add a staff bio
To create a staff bio, you need to do the following:

* create a file in the `_staff` directory called `[staff].md`.
* add their image to `images/staff` directory as `[staff].jpg` (optional)
* fill out the file.  use any other existing file as a guideline for yours.

### Tastybot
To update the commands and descriptions, place the generated json file at `data/tastybot-commands.json`.