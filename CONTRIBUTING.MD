# Contributing
## General Naming Guidelines
In the formatting data of posts and other information (the `---` block at the top of the file), naming conventions matter!

Feel free to use any sane way to write `title:` values, but `name:` and `author:` values **NEED** to be
all lowercase with no spaces or special characters besides `-`.  i.e. only `a-z` and `-`.

This all lowercase, no space naming convention is **also** required for filenames!


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