String getSheepImageForLevel(int level) {
  if (level >= 10) {
    return 'assets/images/sheep3.png';
  } else if (level >= 5) {
    return 'assets/images/sheep2.png';
  }
  return 'assets/images/sheep.jpg';
}
