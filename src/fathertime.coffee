# Description
#   A Hubot script that converts time to your local timezone
#
# Configuration:
#   HUBOT_FATHERTIME_DATEFORMAT
#
# Author:
#   Chris Asche, David Farr, René Filip

moment = require 'moment'
m = require 'moment-timezone'
chrono = require 'chrono-node'

# Default Configuration
dateFormat = if process.env.HUBOT_FATHERTIME_DATEFORMAT then process.env.HUBOT_FATHERTIME_DATEFORMAT else 'MMM Do, h:mm a (z)'

msgHasTimeStrings = (results) ->
  return results.length > 0

# isValidMessage = (message) ->
#   return message.type == 'message'

isHuman = (user) ->
  return user.is_bot == false

getUniqueTz = (users) ->
  timeZones = {}
  for userId, user of users
    if isHuman user
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
    msg += start.clone().tz(z).format(dateFormat) + (if end then ' to ' + end.clone().tz(z).format(dateFormat) else ' ')
    msg += ' ('
    timeZones[z].forEach (user, i) ->
      msg += user.name
      msg += if timeZones[z].length - 1 == i then '' else ', '
      return
    msg += ')' + '\n'

  return msg;


module.exports = (robot) ->

  robot.hear /.*/, (res) ->

    # check if slack adapter is used
    if !res.robot.adapterName == 'slack'
      console.log "Currently, only Slack is supported (since it gives us information about the timezones of the user)"
      return

    message = res.message
    users = res.message.rawMessage._client.users
    user = users[res.message.user.id]

    # check if text contains any time data
    results = chrono.parse res.message.text
    # why is (isValidMessage message) necessary? "|| !isValidMessage message"
    if !msgHasTimeStrings results || !isHuman user
      return

    for result in results
      msg = buildReplyMsg(result, users, user)
      console.log msg
      res.send msg
