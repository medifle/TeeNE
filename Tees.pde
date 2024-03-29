class Tees {
  Tee[] tees = new Tee[2];

  // 0 left, 1 right.
  // Only effective when the tee brainControl is false
  int humanTeeId = 0;

  Tees() {
    tees[0] = new Tee(0);
    tees[1] = new Tee(1);
  }

  Tees(Tee t1, Tee t2) {
    tees[0] = t1;
    tees[1] = t2;
  }

  void useBrain(int teeId, Brain brain) {
    get(teeId).useBrain(brain);
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

  int getEnemyInjuryCD(int teeId) {
    return get(getEnemyTeeId(teeId)).injuryCD;
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

  void syncScore() {
    for (Tee t : tees) {
      t.syncScore();
    }
  }

  boolean areKOEnd() {
    for (Tee t : tees) {
      if (t.HP == 0) {
        return true;
      }
    }
    return false;
  }

  boolean areBrainControl() {
    for (Tee t : tees) {
      if (!t.brainControl) {
        return false;
      }
    }
    return true;
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

  int getSize() {
    return tees.length;
  }
}
