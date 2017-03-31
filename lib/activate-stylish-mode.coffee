{CompositeDisposable} = require "atom"

configSchema = require "./config-schema"
powerEditor = require "./power-editor"

module.exports = ActivatePowerMode =
  config: configSchema
  subscriptions: null
  active: false
  powerEditor: powerEditor

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add "atom-workspace",
      "activate-stylish-mode:toggle": => @toggle()
      "activate-stylish-mode:enable": => @enable()
      "activate-stylish-mode:disable": => @disable()
      "activate-stylish-mode:reset-max-combo": =>
        @powerEditor.getCombo().resetMaxStreak()

    if @getConfig "autoToggle"
      @toggle()

  deactivate: ->
    @subscriptions?.dispose()
    @active = false
    @powerEditor.disable()

  getConfig: (config) ->
    atom.config.get "activate-stylish-mode.#{config}"

  toggle: ->
    if @active then @disable() else @enable()

  enable: ->
    @active = true
    @powerEditor.enable()

  disable: ->
    @active = false
    @powerEditor.disable()
