# Description
#   Middleware for managing peer approvals of Hubot commands
#
# Listener Options:
#   approval:
#     group: String - (Required) name of approvers group
#     peer: bool - (Optional, default false)
#           if true, peer approvals are required;
#           if false and user in approvers group, auto-approve
#
# Commands:
#   hubot approve MAGIC_WORD - Approve a command
#
# Configuration:
#   HUBOT_APPROVAL_TIMEOUT - Number of minutes before command expires (default: 1)
#
# Dependencies:
#   User object is expected to have a 'groups' function (async) will callback
#   with a list of groups the user is in
#
# Notes:
#   robot.respond /approval test$/, { id: 'approval.test', approval: { group: 'admin' } }, (msg) ->
#     msg.reply 'Approval test successful!'
#
#   robot.respond /approval test peer$/, { id: 'approval.test-peer', approval: { group: 'admin', peer: true } }, (msg) ->
#     msg.reply 'Approval test successful!'
#
# Author:
#   Michael Ansel <mansel@box.com>

fs = require 'fs'
path = require 'path'

APPROVAL_TIMEOUT_MS = (process.env.HUBOT_APPROVAL_TIMEOUT or 1) * 60 * 1000 # minutes to ms
WORDS = fs.readFileSync(path.resolve(__dirname, 'words.txt')).toString().split('\n')

class AuthApproval
  constructor: (@robot) ->
    @approvals = {}

    @robot.listenerMiddleware (context, next, done) =>
      return next() unless context.listener.options.approval?

      if not context.response.message.user.groups?
        context.response.reply "Sorry, approvals are broken because your robot is misconfigured. Please ensure you have listener middleware that is adding a 'groups' method onto the User object. Failing closed..."
        @robot.logger.error "Unable to find a 'group' function on the User object: #{Object.keys context.response.message.user}"
        return done()

      context.response.message.user.groups (userGroups) =>
        # Unless peer approval is required, auto-approve if user is in the
        # approvers group
        if not context.listener.options.approval.peer and
           context.listener.options.approval.group in userGroups
          return next()

        # Get a unique magic word (not already in use)
        magic_word = @generateMagicWord exclude: Object.keys(@approvals)
        @approvals[magic_word] =
          context: context
          next: next
          done: done

        context.response.reply "I need approval for that from someone in '#{context.listener.options.approval.group}'. In order to approve, say '#{@robot.name} approve #{magic_word}'."
        # Clean up if not approved within the time limit
        setTimeout (=> delete @approvals[magic_word]), APPROVAL_TIMEOUT_MS

    @robot.respond /approve (.+)$/, (msg) =>
      magic_word = msg.match[1]
      attempt = @approvals[magic_word]
      if not attempt?
        msg.reply "I don't know what you're talking about..."
        return

      msg.message.user.groups (userGroups) =>
        if attempt.context.response.message.user is msg.message.user
          msg.reply "Oh, come on! Self-approving isn't allowed!"
        else if attempt.context.listener.options.approval.group in userGroups
          msg.reply "Approved! Executing '#{attempt.context.response.match[0]}' for #{attempt.context.response.message.user.name}"
          delete @approvals[magic_word]
          attempt.next(attempt.done)
        else
          msg.reply "Sorry, only someone in '#{attempt.context.listener.options.approval.group}' can approve this command!"

    @robot.respond /reject (.+)$/, (msg) =>
      magic_word = msg.match[1]
      attempt = @approvals[magic_word]
      if not attempt?
        msg.reply "I don't know what you're talking about..."
        return

      msg.message.user.groups (userGroups) =>
        if attempt.context.response.message.user is msg.message.user or
           attempt.context.listener.options.approval.group in userGroups
          msg.reply "Oh well... maybe next time!"
          delete @approvals[magic_word]
        else
          msg.reply "Oh hush. You can't do that!"

  generateMagicWord: (options) ->
    exclude_list = options.exclude or []
    magic_word = WORDS[ Math.floor(Math.random() * WORDS.length) ]

    # Keep trying
    until magic_word not in exclude_list
      magic_word = WORDS[ Math.floor(Math.random() * WORDS.length) ]

    magic_word

module.exports = (robot) -> new AuthApproval(robot)
