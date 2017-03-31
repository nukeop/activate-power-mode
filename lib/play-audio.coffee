path = require "path"
fs = require "fs"

module.exports =
  musicPlaying: false
  musicAudio: null

  play: ->
    soundsdir = path.join(__dirname, "..", "audioclips", "dmc")
    sounds = fs.readdirSync(soundsdir)
    randomSound = sounds[Math.floor(Math.random() * sounds.length)]

    audio = new Audio(path.join(soundsdir, randomSound))
    audio.currentTime = 0
    audio.volume = @getConfig "volume"
    audio.play()

  playMusic: ->
    if @musicPlaying
      return

    musicdir = path.join(__dirname, "..", "audioclips", "battle")
    tracks = fs.readdirSync(musicdir)
    randomTrack = tracks[Math.floor(Math.random() * tracks.length)]

    @musicPlaying = true
    @musicAudio = new Audio(path.join(musicdir, randomTrack))
    @musicAudio.currentTime = 0
    @musicAudio.volume = @getConfig "musicVolume"
    @musicAudio.load()
    @musicAudio.play()

  stopMusic: ->
    if @musicAudio != null
      @musicAudio.pause()
      @musicAudio = null
      @musicPlaying = false

  getConfig: (config) ->
    atom.config.get "activate-stylish-mode.playAudio.#{config}"
