# Description
#   A Hubot script that converts time to your local timezone
#
# Configuration:
#   HUBOT_FATHERTIME_DATEFORMAT (optional)
#
# Author:
#   Chris Asche, David Farr, René Filip

moment = require 'moment'
m = require 'moment-timezone'
chrono = require 'chrono-node'

# Default Configuration
dateFormat = if process.env.HUBOT_FATHERTIME_DATEFORMAT then process.env.HUBOT_FATHERTIME_DATEFORMAT else 'MMM Do, h:mm a (z)'

providerIsSlack = (robot) ->
  return robot.adapterName == 'slack'

resultContainsTimeTags = (result) ->
  for tagName, isTrue of result.tags
    if tagName in ["ENMergeDateTimeRefiner", "ENTimeAgoFormatParser", "ENTimeExpressionParser"] && isTrue
      return true
  return false

filterResults = (results) ->
  return (results.filter (result) -> resultContainsTimeTags result)

isHuman = (user) ->
  return user.is_bot == false

getUniqueTz = (users) ->
  timeZones = {}

  for userId, user of users
    tz = user.tz
    if tz == null
      tz = 'America/Los_Angeles'
    if !timeZones[tz]
      timeZones[tz] = []
    timeZones[tz].push(user)

  return timeZones

getTimeDiff = (user) ->
  t = moment()
  return (t.utcOffset() - m.tz(t, user.tz).utcOffset()) * 60000

getBeginDate = (result, user) ->
  start = new Date(result.start.date().getTime() + getTimeDiff(user))
  return m.tz(start.toISOString(), user.tz)

getEndDate = (result, user) ->
  end = if result.end then new Date(result.end.date().getTime() + getTimeDiff(user)) else undefined
  return if end then m.tz(end.toISOString(), user.tz) else undefined

buildReplyMsg = (result, users, user) ->
  timeZones = getUniqueTz(users);
  start = getBeginDate(result, user);
  end = getEndDate(result, user);
  msg = user.name + ': \'' + result.text + '\'\n';

  for z of timeZones
    msg += start.clone().tz(z).format(dateFormat) + (if end then ' to ' + end.clone().tz(z).format(dateFormat) else ' ') + '\n'

  return msg;

module.exports = (robot) ->

  # check if slack adapter is used
  if !providerIsSlack(robot)
    robot.logger.error "Fathertime: Currently, only Slack is supported for fathertime (since it gives us information about the timezones of the user)"

  robot.hear /.*/, (res) ->

    if !providerIsSlack(robot)
      return

    message = res.message

    # check if text contains any time data
    results = filterResults (chrono.parse message.text)
    if results.length <= 0
      return

    channel = message.rawMessage.channel            # current channel
    channels = message.rawMessage._client.channels  # all channels of slack
    allUsers = message.rawMessage._client.users     # all users of slack
    members = channels[channel].members             # members of a channel (ids)

    # filter users: member?, bot?
    users = {}
    for userId, user of allUsers
      if !(userId in members) || !(isHuman user)
        continue
      users[userId] = user
    user = users[message.user.id]

    for result in results
      msg = buildReplyMsg(result, users, user)
      robot.logger.info msg
      res.send msg
