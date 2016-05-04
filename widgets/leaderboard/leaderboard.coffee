class Dashing.Leaderboard extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered
    Dashing.debugMode = true

  onData: (data) ->
