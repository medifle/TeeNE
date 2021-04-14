class Tee {
  int teeId;

  // 1 facing right
  // -1 facing left
  int face;

  int size = 50;
  int maxHP = 14;
  int HP = maxHP;
  int score = 0;

  Brain brain;

  boolean brainControl = false;
  boolean pressLeft = false;
  boolean pressRight = false;
  boolean pressJump = false;
  boolean pressShoot = false;
  boolean prevPressShoot = false; // Only fire once when press&hold the pressShoot key


  /* <physics> */
  PVector pos;
  PVector vel = new PVector(0, 0);

  // Injury cooldown represented by the number of frames
  // Tee is invincible during this period
  int maxInjuryCD = 21;
  int injuryCD = 0;
  float velHitX = -1.68;
  float velHitY = -3.38;

  int jumpable = 1;

  float jumpAcc = -14.61;
  float gravity = 0.75;
  float shortJumpCap = -3;
  float maxVelX = 4.88; // The max speed of velocity X
  float landMoveAcc = 1.6;
  float airMoveAcc = 0.8;
  float airFriction = 0.25;
  float landFriction = 3;
  float maxPosY = terrain.posY-size/2;
  /* </physics> */


  // Weapon being used, only pistol for now
  Pistol pistol = new Pistol(this);

  // Sensors that detect the enemy relative distance
  // If positive, the enemy is on the right. If negative, it is on the left
  PVector enemyDist = new PVector();

  // NN should only know the number of bullets (implicitly)
  // and their relative distances and faces
  // If only one bullet in screen, the front element of the deque is the bullet
  // If two bullets in screen, the front element is the first bullet fired
  ArrayDeque<PBullet> enemyBulletsInAir;

  /* <drawing> */
  color teeColor;
  int lastMoveFrame = 0; // Used for blinking eyes, the last frame tee is idle
  // For recoil animation
  int shootReadyFrame = -99;
  int recoilOffset = 6;
  PShape handShape, bodyShape, eyesShape, blinkEyesShape, hitEyesShape;
  /* </drawing> */

  Tee(int teeId) {
    this.teeId = teeId;
    if (teeId == 0) {
      face = 1;
      pos = new PVector(100, terrain.posY-size/2);
      teeColor = color(32, 32, 128);  // color(169,162,238);
    } else {
      face = -1;
      pos = new PVector(600, terrain.posY-size/2);
      teeColor = color(160, 32, 32);
    }

    loadHandShape();
    loadBodyShape();
    loadEyesShape();
  }

  //TODO
  //Tee(int teeId, int brainN) {

  //}

  void update() {
    updateEnemyData();
    think();

    // calculate the current frame based on think() result
    calcInjury();
    if (tournament.roundEndCode == 0) return;

    move();
    pistol.shoot();
    pistol.bulletsMove();
  }

  void updateEnemyDist(PVector enemyPos) {
    enemyDist.set(enemyPos.x - pos.x, enemyPos.y - pos.y);
  }

  void updateEnemyData() {
    // Update enemyDist
    PVector enemyPos = tees.getEnemyPos(teeId);
    updateEnemyDist(enemyPos);

    // Update enemy bullet dists
    enemyBulletsInAir = tees.getEnemyBulletsInAir(teeId);
    for (PBullet b : enemyBulletsInAir) {
      b.updateBulletEnemyDist(pos.x, pos.y);
    }
  }

  void think() {
    if (brainControl) {
      /* <prepare input> */
      float[] in = new float[14];
      in[0] = map(vel.y, -15, 15, -1, 1); // (-1,1)
      in[1] = face; // {-1,1}
      in[2] = pistol.shootable; // {0,1}
      in[3] = jumpable; // {0,1}
      in[4] = map(injuryCD, 0, 20, 0, 1); // [0,1]
      in[5] = map(enemyDist.x, -762, 762, -2.4, 2.4); // [-2.4,2.4]
      in[6] = map(enemyDist.y, -150, 150, -1, 1); // (-1,1)

      PBullet eb0 = enemyBulletsInAir.peekFirst();
      in[7] = (eb0 == null ? 0 : eb0.face); // {-1,0,1}
      in[8] = (eb0 == null ? 0 : map(eb0.bulletEnemyDist.x, -685, 685, -2.2, 2.2)); // [-2.2,2.2]
      in[9] = (eb0 == null ? 0 : map(eb0.bulletEnemyDist.y, -150, 150, -1, 1)); // (-1,1)

      PBullet eb1 = null;
      if (enemyBulletsInAir != null && enemyBulletsInAir.size() > 1) {
        eb1 = enemyBulletsInAir.peekLast();
      }
      in[10] = (eb1 == null ? 0 : eb1.face); // {-1,0,1}
      in[11] = (eb1 == null ? 0 : map(eb1.bulletEnemyDist.x, -685, 685, -2.2, 2.2)); // [-2.2,2.2]
      in[12] = (eb1 == null ? 0 : map(eb1.bulletEnemyDist.y, -150, 150, -1, 1)); // (-1,1)
      in[13] = map(tees.getEnemyInjuryCD(teeId), 0, 20, 0, 1); // [0,1]
      /* </prepare input> */

      NeuralNetwork nn = brain.getNN();
      float[] out = nn.feedforward(in);

      // Convert output value to game control intruction
      pressLeft = (out[0] > 0.0);
      pressRight = (out[1] > 0.0);
      pressJump = (out[2] > 0.0);
      pressShoot = (out[3] > 0.0);
    }
  }

  void calcInjury() {
    ArrayDeque<PBullet> enemyBulletsInAir = tees.getEnemyBulletsInAir(teeId);
    for (PBullet b : enemyBulletsInAir) {
      if (injuryCD == 0 && b.bulletEnemyDist.x > -24 && b.bulletEnemyDist.x < 24
        && b.bulletEnemyDist.y > -36 && b.bulletEnemyDist.y < 42) {
        injuryCD = maxInjuryCD;
        face = -1 * b.face; // When hit, let player face the bullet-coming direction
        vel.x = velHitX * face; // Hit physics
        vel.y = velHitY;
        b.isShot = false; // Bullet disappears
        HP--;

        if (HP == 0) {
          tournament.endRound();
        }
      }
    }

    if (injuryCD > 0) {
      injuryCD--;
      pistol.shootable = 0;
      jumpable = 0;

      // Apply hit physics since move() does not do this
      vel.y += gravity;
      float newPosY = pos.y + vel.y;
      yBoundaryCalibrate(newPosY);

      // Simple X axis sliding
      float newPosX = pos.x + vel.x;
      xBoundaryCalibrate(newPosX);
    }
  }

  void yBoundaryCalibrate(float newPosY) {
    if (newPosY > maxPosY) {
      pos.y = maxPosY;
      vel.y = 0;
    } else {
      pos.y = newPosY;
    }
  }

  void xBoundaryCalibrate(float newPosX) {
    if (newPosX >= terrain.leftBoundary && newPosX <= terrain.rightBoundary) {
      pos.x = newPosX;
    } else if (newPosX < terrain.leftBoundary) {
      pos.x = terrain.leftBoundary;
    } else if (newPosX > terrain.rightBoundary) {
      pos.x = terrain.rightBoundary;
    }
  }

  void move() {
    if (injuryCD > 0) return;

    // ------JUMP------
    if (pressJump) {
      if (jumpable == 1) {
        vel.y = jumpAcc;
        jumpable = 0;
      } else {
        vel.y += gravity;
      }
    } else if (jumpable == 0) {   // If jump key is released and the player is in the air
      if (vel.y < shortJumpCap) { // Player velocity is capped to implement short jump
        vel.y = shortJumpCap;
      } else {
        vel.y += gravity;
      }
    }

    // Y boundaries check
    float newPosY = pos.y + vel.y; // Calculate the new position Y value
    yBoundaryCalibrate(newPosY);

    // If landed, only restore the jump ability when the jump key is released
    if (pos.y == maxPosY && !pressJump) {
      jumpable = 1;
    }

    // ------LEFT or RIGHT------
    if (pressLeft && !pressRight) {
      face = -1;
      vel.x -= isInAir() ? airMoveAcc : landMoveAcc;
    } else if (!pressLeft && pressRight) {
      face = 1;
      vel.x += isInAir() ? airMoveAcc : landMoveAcc;
    } else {
      vel.x += (isInAir() ? airFriction : landFriction) * (-1 * face);
    }

    // Max X velocity cap
    if (vel.x * face > maxVelX) {
      vel.x = maxVelX * face;
    } else if (vel.x * face < 0) {
      vel.x = 0; // Stop
    }

    // X boundaries check
    float newPosX = pos.x + vel.x;
    xBoundaryCalibrate(newPosX);
  }

  void updateLastMoveFrame() {
    lastMoveFrame = tournament.roundFrameCtr;
  }

  boolean isInAir() {
    return pos.y < maxPosY;
  }

  void cancelPressStatus() {
    pressLeft = false;
    pressRight = false;
    pressJump = false;
    pressShoot = false;
  }

  void calcScore() {
    score = (maxHP - tees.getEnemyHP(teeId)) * 10 - (maxHP - HP) * 5;
    if (tournament.winner == teeId) {
      score += 100 + tournament.roundTimeLeft;
    } else if (tournament.winner == tees.getEnemyTeeId(teeId)) {
      score -= 100 + tournament.roundTimeLeft;
    }
  }

  void render() {
    // Injury invincible animation
    if (injuryCD > 0) {
      if (tournament.roundFrameCtr % 4 > 1) {
        pistol.pistolShape.setVisible(true);
        handShape.setVisible(true);
        bodyShape.setVisible(true);
        hitEyesShape.setVisible(true);
      } else {
        pistol.pistolShape.setVisible(false);
        handShape.setVisible(false);
        bodyShape.setVisible(false);
        hitEyesShape.setVisible(false);
      }
    } else {
      pistol.pistolShape.setVisible(true);
      handShape.setVisible(true);
      bodyShape.setVisible(true);
      hitEyesShape.setVisible(true);
    }

    // Recoil animation
    if (pistol.shootReady()) {
      shootReadyFrame = tournament.roundFrameCtr;
    }
    pushMatrix();
    if (tournament.roundFrameCtr - shootReadyFrame < 4) {
      translate(-1 * recoilOffset * face, 0);
    }
    pistol.render(pos.x, pos.y);
    renderHand(pos.x, pos.y);
    popMatrix();

    renderBody(pos.x, pos.y);
    renderEyes(pos.x, pos.y);
    renderHP();
  }

  void renderHP() {
    int offsetX = 10;
    int lx = 10 + offsetX;
    int rx = width-234-offsetX;
    int y = 10;
    int h = 18;
    int halfInnerH = (h-2)/2;
    int unitLength = 16;

    fill(60);
    stroke(20);
    strokeWeight(2);
    if (teeId == 0) {
      rect(lx-1, y-1, maxHP*unitLength+2, h); // black background

      fill(144, 242, 97); // shallow green layer
      noStroke();
      rect(lx, y, HP*unitLength, h-2);

      fill(117, 191, 80); // dark green layer
      rect(lx, y+halfInnerH, HP*unitLength, halfInnerH);
    } else {
      rect(rx-1, y-1, maxHP*unitLength+2, h);

      fill(144, 242, 97);
      noStroke();
      rect(rx, y, HP*unitLength, h-2);

      fill(117, 191, 80);
      rect(rx, y+halfInnerH, HP*unitLength, halfInnerH);
    }

    stroke(20); // Restore stroke
  }

  void loadBodyShape() {
    bodyShape = createShape(ELLIPSE, 0, 0, size, size);
    bodyShape.setStroke(teeColor);
    bodyShape.setStrokeWeight(2.5);
    if (teeId == 0) {
      bodyShape.setFill(color(221, 221, 233));
    } else {
      bodyShape.setFill(color(237, 221, 221));
    }
  }

  void renderBody(float x, float y) {
    shape(bodyShape, x, y);
  }

  void loadEyesShape() {
    eyesShape = createShape(GROUP);

    PShape e0 = createShape(ELLIPSE, 3, -3, 7, 14);
    e0.setFill(color(20));
    e0.setStroke(color(0));
    e0.setStrokeWeight(1);

    PShape e1 = createShape(ELLIPSE, 14, -3, 7, 14);
    e1.setFill(color(20));
    e1.setStroke(color(0));
    e1.setStrokeWeight(1);

    eyesShape.addChild(e0);
    eyesShape.addChild(e1);


    blinkEyesShape = createShape(GROUP);
    PShape b0 = createShape(ELLIPSE, 3, -3, 7, 2);
    b0.setFill(color(20));
    b0.setStroke(color(0));
    b0.setStrokeWeight(1);

    PShape b1 = createShape(ELLIPSE, 14, -3, 7, 2);
    b1.setFill(color(20));
    b1.setStroke(color(0));
    b1.setStrokeWeight(1);

    blinkEyesShape.addChild(b0);
    blinkEyesShape.addChild(b1);


    hitEyesShape = createShape(GROUP);

    PShape h0 = createShape();
    h0.beginShape();
    h0.noFill();
    h0.stroke(0);
    h0.strokeWeight(2);
    h0.vertex(-3, 0);
    h0.vertex(8, 0);
    h0.vertex(2, -6);
    h0.endShape();

    PShape h1 = createShape();
    h1.beginShape();
    h1.noFill();
    h1.stroke(0);
    h1.strokeWeight(2);
    h1.vertex(20, 0);
    h1.vertex(9, 0);
    h1.vertex(15, -6);
    h1.endShape();

    hitEyesShape.addChild(h0);
    hitEyesShape.addChild(h1);
  }

  void renderEyes(float x, float y) {
    if (face == -1) {
      pushMatrix();
      scale(-1, 1);
      if (injuryCD > 0) {
        shape(hitEyesShape, face*x, y);
      } else {
        if ((tournament.roundFrameCtr - lastMoveFrame) > 300 && (tournament.roundFrameCtr - lastMoveFrame) % 300 < 5) {
          shape(blinkEyesShape, face*x, y);
        } else {
          shape(eyesShape, face*x, y);
        }
      }
      popMatrix();
    } else {
      if (injuryCD > 0) { // Injury animation
        shape(hitEyesShape, x, y);
      } else {
        // Blink every 5s when idle
        if ((tournament.roundFrameCtr - lastMoveFrame) > 300 && (tournament.roundFrameCtr - lastMoveFrame) % 300 < 5) {
          shape(blinkEyesShape, x, y);
        } else { // Eyes
          shape(eyesShape, x, y);
        }
      }
    }
  }

  void loadHandShape() {
    handShape = createShape();
    handShape.beginShape();
    handShape.fill(220);
    handShape.stroke(0);
    handShape.strokeWeight(1.5);
    handShape.curveVertex(25, 0);

    handShape.curveVertex(25, 0);
    handShape.curveVertex(28, 2);
    handShape.curveVertex(30, 5);
    handShape.curveVertex(28, 9);
    handShape.curveVertex(21, 14);

    handShape.curveVertex(21, 14);
    handShape.endShape();
  }

  void renderHand(float x, float y) {
    if (face == -1) {
      pushMatrix();
      scale(-1, 1);
      shape(handShape, face * x, y);
      popMatrix();
    } else {
      shape(handShape, x, y);
    }
  }

  void showJoypad() {
    fill(100);
    int offsetX = 0;
    if (teeId == 1) {
      offsetX = 635;
    }

    int posY = 170;

    textSize(18);
    if (pressLeft) {
      text("L", (24 + offsetX), terrain.posY + posY);
    }
    if (pressRight) {
      text("R", (48 + offsetX), terrain.posY + posY);
    }
    // TBD: need a keymap config
    if (pressJump) {
      text("Z", (72 + offsetX), terrain.posY + posY);
    }
    if (pressShoot) {
      text("X", (96 + offsetX), terrain.posY + posY);
    }
  }

  void showDebugInfo() {
    if (debug == false) return;

    fill(20);
    noStroke();
    textFont(FontSansSerif);
    textSize(12);

    int offsetX = 0;
    if (teeId == 1) {
      offsetX = 420;
    }

    // Tee positions and velocities
    text("pos.x " + nf(pos.x, 1, 2), 10 + offsetX, terrain.posY + 20);
    text("pos.y " + nf(pos.y, 1, 2), 10 + offsetX, terrain.posY + 35);
    text("vel.x " + nf(vel.x, 1, 2), 100 + offsetX, terrain.posY + 20);
    text("vel.y " + nf(vel.y, 1, 2), 100 + offsetX, terrain.posY + 35);

    // EnemyDist
    text("eds.x " + nf(enemyDist.x, 1, 2), 10 + offsetX, terrain.posY + 50);
    text("eds.y " + nf(enemyDist.y, 1, 2), 10 + offsetX, terrain.posY + 65);

    text("shootable " + pistol.shootable, 10+offsetX, terrain.posY + 80);
    text("jumpable " + jumpable, 10+offsetX, terrain.posY + 95);
    text("injuryCD " + injuryCD, 100+offsetX, terrain.posY + 80);

    tees.calcScore();
    text("score " + score, 100+offsetX, terrain.posY + 95);

    // Bullet positions
    PBullet b0 = pistol.bulletsInAir.peekFirst();
    text("bu0.x " + nf(b0 == null ? 0 : b0.pos.x, 1, 1), 175+offsetX, terrain.posY + 20);
    text("bu0.y " + nf(b0 == null ? 0 : b0.pos.y, 1, 1), 175+offsetX, terrain.posY + 35);

    PBullet b1 = null;
    if (pistol.bulletsInAir.size() > 1) { // If 2 bullets in the air, get the last one
      b1 = pistol.bulletsInAir.peekLast();
    }
    text("bu1.x " + nf(b1 == null ? 0 : b1.pos.x, 1, 1), 260+offsetX, terrain.posY + 20);
    text("bu1.y " + nf(b1 == null ? 0 : b1.pos.y, 1, 1), 260+offsetX, terrain.posY + 35);

    // Enemy bullet relative dists
    PBullet eb0 = null;
    if (enemyBulletsInAir != null) {
      eb0 = enemyBulletsInAir.peekFirst();
    }
    text("eb0.x " + nf(eb0 == null ? 0 : eb0.bulletEnemyDist.x, 1, 1), 175+offsetX, terrain.posY + 50);
    text("eb0.y " + nf(eb0 == null ? 0 : eb0.bulletEnemyDist.y, 1, 1), 175+offsetX, terrain.posY + 65);

    PBullet eb1 = null;
    if (enemyBulletsInAir != null && enemyBulletsInAir.size() > 1) {
      eb1 = enemyBulletsInAir.peekLast();
    }
    text("eb1.x " + nf(eb1 == null ? 0 : eb1.bulletEnemyDist.x, 1, 1), 260+offsetX, terrain.posY + 50);
    text("eb1.y " + nf(eb1 == null ? 0 : eb1.bulletEnemyDist.y, 1, 1), 260+offsetX, terrain.posY + 65);

    // Enemy bullet faces
    text("eb0.f " + (eb0 == null ? 0 : eb0.face), 175+offsetX, terrain.posY + 80);
    text("eb1.f " + (eb1 == null ? 0 : eb1.face), 260+offsetX, terrain.posY + 80);


    if (teeId == 0) {
      text("isInAir " + isInAir(), 10, terrain.posY + 150);
      text("frameCtr " + tournament.roundFrameCtr, 10, terrain.posY + 165);
      text("lastMoveFrame " + lastMoveFrame, 10, terrain.posY + 180);
      text("shootReadyFrame " + shootReadyFrame, 10, terrain.posY + 195);
    }

    stroke(20); // Restore stroke
  }
}
