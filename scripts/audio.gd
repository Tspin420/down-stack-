extends Node

const NAMES = ["move","rotate","hold","drop","lock","clear1","clear2","clear3","clear4","tspin","perfect","garbage","warning","tick","go","win","lose","menu"]
var voices = {}
var music: AudioStreamPlayer
var sfx_volume = 0.65
var music_volume = 0.22
var last_play = {}

func _ready():
 for effect in NAMES:
  var voice = AudioStreamPlayer.new()
  voice.stream = load("res://assets/audio/"+effect+".wav")
  voice.max_polyphony = 4
  add_child(voice)
  voices[effect] = voice
 music = AudioStreamPlayer.new()
 var loop: AudioStreamWAV = load("res://assets/audio/music.wav")
 var frames = roundi(loop.get_length()*loop.mix_rate)
 loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
 loop.loop_begin = 0
 loop.loop_end = frames
 music.stream = loop
 add_child(music)
 set_levels(sfx_volume,music_volume)
 # Headless tests/hosts have no audio output and need no perpetual music loop.
 if DisplayServer.get_name() != "headless": music.play()

func set_levels(sfx: float,background: float):
 sfx_volume = clampf(sfx,0.0,1.0)
 music_volume = clampf(background,0.0,1.0)
 for voice in voices.values(): voice.volume_db = linear_to_db(maxf(sfx_volume,0.00001))
 if music: music.volume_db = linear_to_db(maxf(music_volume,0.00001))

func play(effect: String):
 if not voices.has(effect) or sfx_volume <= 0: return
 var now = Time.get_ticks_msec()
 # Fast ARR stays crisp without overwhelming other cues.
 if effect == "move" and now-int(last_play.get(effect,-1000)) < 42: return
 last_play[effect] = now
 voices[effect].play()

func _exit_tree():
 if is_instance_valid(music): music.stop()
 for voice in voices.values():
  if is_instance_valid(voice): voice.stop()
