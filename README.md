# hubot-fathertime

*this script only works with the [Slack](https://github.com/slackhq/hubot-slack) adapter*

A Hubot script that converts any time to your (and others) local timezone.

![example](https://raw.githubusercontent.com/filipre/hubot-fathertime/master/example.png)

Please see [dfarr/fathertime](https://github.com/dfarr/fathertime) for the original project

## Installation

In hubot project repo, run:

`npm install hubot-fathertime --save`

Then add **hubot-fathertime** to your `external-scripts.json`:

```json
[
  "hubot-fathertime"
]
```

## Configuration

(optional) You can set the `HUBOT_FATHERTIME_DATEFORMAT` environment variable to return a custom date format.
