throttle = require "lodash.throttle"
debounce = require "lodash.debounce"
defer = require "lodash.defer"
sample = require "lodash.sample"
playAudio = require "./play-audio"

module.exports =
  playAudio: playAudio
  currentStreak: 0
  reached: false
  maxStreakReached: false
  ranks: [
    {name: "Deadly!", color: "#ffffff"},
    {name: "Carnage!", color: "#3498db"},
    {name: "Brutal!", color: "#f1c40f"},
    {name: "Atomic!", color: "#f39c12"},
    {name: "Smokin'!", color: "#e74c3c"},
    {name: "Smokin' Style!!", color: "#e74c3c"},
    {name: "Smokin' Sick Style!!!", color: "#e74c3c"}
  ]

  reset: ->
    @container?.parentNode?.removeChild @container

  destroy: ->
    @reset()
    @container = null
    @debouncedEndStreak?.cancel()
    @debouncedEndStreak = null
    @streakTimeoutObserver?.dispose()
    @opacityObserver?.dispose()
    @currentStreak = 0
    @reached = false
    @maxStreakReached = false


  createElement: (name, parent)->
    @element = document.createElement "div"
    @element.classList.add name
    parent.appendChild @element if parent
    @element

  setup: (editorElement) ->
    if not @container
      @throttledStopMusic = throttle @playAudio.stopMusic.bind(@playAudio), 100, trailing: false
      @maxStreak = @getMaxStreak()
      @container = @createElement "streak-container"
      @container.classList.add "combo-zero"
      @title = @createElement "title", @container
      @title.textContent = "Combo"
      @max = @createElement "max", @container
      @max.textContent = "Max #{@maxStreak}"
      @rank = @createElement "rank", @container
      @counter = @createElement "counter", @container
      @bar = @createElement "bar", @container
      @exclamations = @createElement "exclamations", @container
      @streakTimeoutObserver?.dispose()
      @streakTimeoutObserver = atom.config.observe 'activate-stylish-mode.comboMode.streakTimeout', (value) =>
        @streakTimeout = value * 1000
        @endStreak()
        @debouncedEndStreak?.cancel()
        @debouncedEndStreak = debounce @endStreak.bind(this), @streakTimeout

      @opacityObserver?.dispose()
      @opacityObserver = atom.config.observe 'activate-stylish-mode.comboMode.opacity', (value) =>
        @container?.style.opacity = value

    @exclamations.innerHTML = ''

    editorElement.querySelector(".scroll-view").appendChild @container

    if @currentStreak
      leftTimeout = @streakTimeout - (performance.now() - @lastStreak)
      @refreshStreakBar leftTimeout

    @renderStreak()

  increaseStreak: ->
    @lastStreak = performance.now()
    @debouncedEndStreak()

    @currentStreak++

    @container.classList.remove "combo-zero"
    if @currentStreak > @maxStreak
      @increaseMaxStreak()

    @showExclamation() if @currentStreak > 0 and @currentStreak % @getConfig("exclamationEvery") is 0

    if @currentStreak >= @getConfig("activationThreshold") and not @reached
      @reached = true
      @container.classList.add "reached"

    if @reached
      currentRank = @ranks[Math.min(@ranks.length-1, Math.floor(@currentStreak/@getConfig("activationThreshold")) - 1)]
      @rank.textContent = currentRank.name
      @rank.style.color = currentRank.color

    @refreshStreakBar()

    @renderStreak()

  endStreak: ->
    @currentStreak = 0
    @reached = false
    @maxStreakReached = false
    @container.classList.add "combo-zero"
    @container.classList.remove "reached"
    @rank.textContent = ""
    @throttledStopMusic()
    @renderStreak()

  renderStreak: ->
    @counter.textContent = @currentStreak
    @counter.classList.remove "bump"

    defer =>
      @counter.classList.add "bump"

  refreshStreakBar: (leftTimeout = @streakTimeout) ->
    scale = leftTimeout / @streakTimeout
    @bar.style.transition = "none"
    @bar.style.transform = "scaleX(#{scale})"

    setTimeout =>
      @bar.style.transform = ""
      @bar.style.transition = "transform #{leftTimeout}ms linear"
    , 100

  showExclamation: (text = null) ->
    exclamation = document.createElement "span"
    exclamation.classList.add "exclamation"
    text = sample @getConfig "exclamationTexts" if text is null
    exclamation.textContent = text

    @exclamations.insertBefore exclamation, @exclamations.childNodes[0]
    setTimeout =>
      if exclamation.parentNode is @exclamations
        @exclamations.removeChild exclamation
    , 2000

  hasReached: ->
    @reached

  getMaxStreak: ->
    maxStreak = localStorage.getItem "activate-stylish-mode.maxStreak"
    maxStreak = 0 if maxStreak is null
    maxStreak

  increaseMaxStreak: ->
    localStorage.setItem "activate-stylish-mode.maxStreak", @currentStreak
    @maxStreak = @currentStreak
    @max.textContent = "Max #{@maxStreak}"
    @showExclamation "NEW MAX!!!" if @maxStreakReached is false
    @maxStreakReached = true

  resetMaxStreak: ->
    localStorage.setItem "activate-stylish-mode.maxStreak", 0
    @maxStreakReached = false
    @maxStreak = 0
    if @max
      @max.textContent = "Max 0"

  getConfig: (config) ->
    atom.config.get "activate-stylish-mode.comboMode.#{config}"
