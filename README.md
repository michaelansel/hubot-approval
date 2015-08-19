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

Note that **hubot-approval** needs to be added *after* whatever module is adding the `groups` function to the `User` object.

## Assumptions

**hubot-approval** assumes that there is a piece of middleware executing prior to it that modifies the `User` object to add a group lookup function (`groups`). A simple version is below:

```coffeescript
robot.listenerMiddleware (context, next, done) ->
  context.response.message.user.groups = (cb) ->
    cb(robot.brain.get('userGroups')[context.response.message.user.name] or [])
```

## Sample Interaction

```
user1>> hubot do something
hubot>> user1: I need approval for that from someone in 'admin'. In order to approve, say 'hubot approve cheese'.
user2>> hubot approve cheese
hubot>> user2: Approved! Executing 'hubot do something' for user1
hubot>> user1: I did something!
```
