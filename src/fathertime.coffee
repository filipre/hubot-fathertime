# Description
#   A Hubot script that converts time to your local timezone
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Chris Asche, David Farr, René Filip

module.exports = (robot) ->
  robot.respond /hello/, (res) ->
    res.reply "hello!"

  robot.hear /orly/, ->
    # implies that hubot is using the slack adapter.
    # currently, there is no "general" way to get the users' timezones.
    console.log(res.message.rawMessage._client.users);
    res.send "yarly"
