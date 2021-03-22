class Tees {
  Tee[] tees = new Tee[2];
  int humanTeeId; // 0 is player 1, 1 is player 2

  Tees() {
    tees[0] = new Tee(0);
    tees[1] = new Tee(1);
    humanTeeId = 0;
  }

  Tees(Tee t1, Tee t2, int id) {
    tees[0] = t1;
    tees[1] = t2;
    humanTeeId = id;
  }

  Tee get(int id) {
    return tees[id];
  }

  int getEnemyTeeId(int teeId) {
    return (teeId == 0 ? 1 : 0);
  }

  int getEnemyHP(int teeId) {
    return get(getEnemyTeeId(teeId)).HP;
  }

  // teeId The tee who need the info, not the enemy's teeId
  PVector getEnemyPos(int teeId) {
    int enemyTeeId = getEnemyTeeId(teeId);
    return get(enemyTeeId).pos;
  }

  ArrayDeque<PBullet> getEnemyBulletsInAir(int teeId) {
    int enemyTeeId = getEnemyTeeId(teeId);
    return get(enemyTeeId).pistol.bulletsInAir;
  }

  void switchPlayer() {
    humanTeeId = (humanTeeId == 0 ? 1 : 0);
  }

  Tee getHumanPlayer() {
    return get(humanTeeId);
  }

  void update() {
    for (Tee t : tees) {
      t.update();
    }
  }

  void render() {
    for (Tee t : tees) {
      t.render();
    }
  }

  void calcScore() {
    for (Tee t : tees) {
      t.calcScore();
    }
  }
  
  boolean isKOEnd() {
    for (Tee t : tees) {
      if (t.HP == 0) {
        return true;
      }
    }
    return false;
  }

  void showJoypad() {
    for (Tee t : tees) {
      t.showJoypad();
    }
  }

  void showDebugInfo() {
    for (Tee t : tees) {
      t.showDebugInfo();
    }
  }
}
