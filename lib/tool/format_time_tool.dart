String timerToStr(int duration) {
  if (duration <= 60) {
    return "00:${duration.toString().padLeft(2, '0')}";
  } else {
    return "${(duration / 60).truncate().toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}";
  }
}
