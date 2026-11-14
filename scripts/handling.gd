class_name DownstackHandling
extends RefCounted

# Zero selects the original baseline. Custom levels 1–10 retain their speeds.
const DAS_TICKS = [36,32,28,24,20,18,16,14,12,10]
const ARR_MS = [100.0,83.333333,66.666667,50.0,33.333333,30.0,26.666667,23.333333,20.0,16.666667]

static func das_ms(level: int) -> float:
 return DAS_TICKS[4 if level == 0 else clampi(level,1,10)-1]*1000.0/120.0

static func arr_ms(level: int) -> float:
 return ARR_MS[4 if level == 0 else clampi(level,1,10)-1]

static func level_for_ms(kind: String,value: float) -> int:
 var nearest = 0
 var distance = INF
 for level in range(0,11):
  var delta = absf(value-(das_ms(level) if kind == "das" else arr_ms(level)))
  if delta < distance:
   nearest = level
   distance = delta
 return nearest

static func time_text(milliseconds: float) -> String:
 var total = maxi(0,roundi(milliseconds))
 return "%02d:%02d.%03d"%[total/60000,(total/1000)%60,total%1000]
