# festival.el

`festival.el` provides a simple interface into [the festival speech
synthesis program](http://www.cstr.ed.ac.uk/projects/festival/).

## Commentary:

`festival.el` provides a simple interface into [the festival speech
synthesis program](http://www.cstr.ed.ac.uk/projects/festival/). Commands
include:

| Command | Purpose |
| --- | --- |
| `festival-start` | Start a festival process |
| `festival-stop` | Stop a festival process |
| `festival-say` | Prompt for some text and say it |
| `festival-read-file` | Read the content of a file |
| `festival-read-buffer` | Read the content of the current buffer |
| `festival-read-region` | Read the content of the current active region |
| `festival-intro` | Play the standard festival intro |
| `festival-voice-english-male` | Select the standard English male voice |
| `festival-voice-US-male` | Select the standard US male voice |
| `festival-voice` | Prompt for and select a voice |
| `festival-hook-doctor` | Hook into the Emacs psychotherapist |
| `festival-unhook-doctor` | Unhook the Emacs psychotherapist |
| `festival-hook-message` | Read any message displayed in the minibuffer |
| `festival-unhook-message` | Stop reading any message displayed in the minibuffer |
| `festival-hook-error` | Read any error displayed in the minibuffer |
| `festival-unhook-error` | Stop reading any error displayed in the minibuffer |
| `festival-describe-function` | Read the description of a given Emacs function |
| `festival-spook` | Excite any hidden microphones |

BTW, it was only once I'd more or less finished writing the first version of
this that I noticed that a festival.el comes with festival itself (yeah, I
know, I should spend more time examining the contents of software packages).
As it is, I decided to press on with this anyway because I'd done a couple
of different things and, more importantly, I was having far too much fun.
