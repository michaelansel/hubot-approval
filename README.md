# hubot-approval

Middleware for managing peer approvals of Hubot commands

See [`src/approval.coffee`](src/approval.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-approval --save`

Then add **hubot-approval** to your `external-scripts.json`:

```json
[
  "hubot-approval"
]
```

## Sample Interaction

```
user1>> hubot hello
hubot>> hello!
```
