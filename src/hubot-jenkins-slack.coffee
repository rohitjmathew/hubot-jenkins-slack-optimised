# Notifies about Jenkins builds via Jenkins Notification Plugin
#
# Configuration:
#
#   Just put this url
#   <HUBOT_URL>:<PORT>/<HUBOT_NAME>/jenkins?room=<room> to your
#   Jenkins Notification config. See here:
#   https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin
#
# Commands:
#   None
#
# Environment:
#   HUBOT_JENKINS_COLOR_ABORTED: color for aborted builds
#   HUBOT_JENKINS_COLOR_FAILURE: color for failed builds
#   HUBOT_JENKINS_COLOR_FIXED: color for fixed builds
#   HUBOT_JENKINS_COLOR_STILL_FAILING: color for still failing builds
#   HUBOT_JENKINS_COLOR_SUCCESS: color for success builds
#   HUBOT_JENKINS_COLOR_DEFAULT: default color for builds
#
# URLS:
#   POST /<robot-name>/jenkins?room=<room>
#
# Authors:
#   inkel

HUBOT_JENKINS_COLOR_ABORTED       = process.env.HUBOT_JENKINS_COLOR_ABORTED       || "warning"
HUBOT_JENKINS_COLOR_FAILURE       = process.env.HUBOT_JENKINS_COLOR_FAILURE       || "danger"
HUBOT_JENKINS_COLOR_FIXED         = process.env.HUBOT_JENKINS_COLOR_FIXED         || "#d5f5dc"
HUBOT_JENKINS_COLOR_STILL_FAILING = process.env.HUBOT_JENKINS_COLOR_STILL_FAILING || "danger"
HUBOT_JENKINS_COLOR_SUCCESS       = process.env.HUBOT_JENKINS_COLOR_SUCCESS       || "good"
HUBOT_JENKINS_COLOR_DEFAULT       = process.env.HUBOT_JENKINS_COLOR_DEFAULT       || "#ffe094"

module.exports = (robot) ->
  robot.router.post "/#{robot.name}/jenkins", (req, res) ->
    room = req.query.room

    unless room?
      res.status(400).send("Bad Request").end()
      return

    if req.query.debug
      console.log req.body

    data = req.body

    robot.logger.info "Data from jenkins:", data

    res.status(202).end()

    return if data.build.phase == "COMPLETED"

    payload =
      message:
        room: "##{room}"
      content:
        fields: []

    payload.content.fields.push
      title: "Phase"
      value: data.build.phase
      short: true

    switch data.build.phase
      when "FINALIZED"
        status = "#{data.build.phase} with #{data.build.status}"

        payload.content.fields.push
          title: "Status"
          value: data.build.status
          short: true

        payload.content.fields.push
          title: "Job"
          value: data.display_name
          short: true

        color = switch data.build.status
          when "ABORTED"       then HUBOT_JENKINS_COLOR_ABORTED
          when "FAILURE"       then HUBOT_JENKINS_COLOR_FAILURE
          when "FIXED"         then HUBOT_JENKINS_COLOR_FIXED
          when "STILL FAILING" then HUBOT_JENKINS_COLOR_STILL_FAILING
          when "SUCCESS"       then HUBOT_JENKINS_COLOR_SUCCESS
          else                      HUBOT_JENKINS_COLOR_DEFAULT

        params = data.build.parameters

        if params.environment
          payload.content.fields.push
            title: "Environment"
            value: params.environment
            short: true
          payload.content.fields.push
            title: "Branch"
            value: params.branch
            short: true

      when "STARTED"
        status = data.build.phase
        color = "#ffe094"

        payload.content.fields.push
          title: "Job"
          value: data.display_name
          short: true

        payload.content.fields.push
          title: "Build #"
          value: "<#{data.build.full_url}|#{data.build.number}>"
          short: true

        params = data.build.parameters

        if params.environment
          payload.content.fields.push
            title: "Environment"
            value: params.environment
            short: true
          payload.content.fields.push
            title: "Branch"
            value: params.branch
            short: true
        
    payload.content.color    = color
    payload.content.pretext  = "Jenkins #{data.name} #{status} #{data.build.full_url}"
    payload.content.fallback = payload.content.pretext

    if req.query.debug
      console.log payload

    robot.emit "slack-attachment", payload
