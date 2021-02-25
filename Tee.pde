class Tee {
  int teeId;

  PVector pos;
  PVector vel = new PVector(0, 0);

  int face;
  int size = 50;
  int maxHP = 14;
  int HP = maxHP;

  boolean isBot = false;
  boolean pressLeft = false;
  boolean pressRight = false;
  boolean pressJump = false;
  boolean pressShoot = false;
  boolean prevPressShoot = false; // Only fire once when press&hold the pressShoot key

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

  Pistol pistol = new Pistol(this); // Current weapon, only pistol for now

  // Sensors that detect the enemy relative distance
  // If positive, the enemy is on the right. If negative, it is on the left
  PVector enemyDist = new PVector();

  // NN should only know the number of bullets (implicitly)
  // and their relative distances and faces
  // For distance
  // If only one bullet in screen, always use the front element
  // If two bullets in screen, the front element is the first bullet fired
  ArrayDeque<PBullet> enemyBulletsInAir;

  // For drawing
  color teeColor;
  int lastMoveFrame = 0; // Used for blinking eyes, the last frame tee is idle
  // For recoil animation
  int shootReadyFrame = -99;
  int recoilOffset = 6;
  PShape handShape, bodyShape, eyesShape, blinkEyesShape, hitEyesShape;

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

  void update() {
    processSensorData();

    calcInjury();
    move();
    pistol.shoot();
    pistol.bulletsMove();
  }

  void updateEnemyDist(PVector enemyPos) {
    enemyDist.set(enemyPos.x - pos.x, enemyPos.y - pos.y);
  }

  void processSensorData() {
    // Update enemyDist
    PVector enemyPos = tees.getEnemyPos(teeId);
    updateEnemyDist(enemyPos);

    // Update enemy bullet dists
    enemyBulletsInAir = tees.getEnemyBulletsInAir(teeId);
    for (PBullet b : enemyBulletsInAir) {
      b.updateEnemyDist(pos.x, pos.y);
    }

    // TODO calc the input for NN
  }

  void calcInjury() {
    ArrayDeque<PBullet> enemyBulletsInAir = tees.getEnemyBulletsInAir(teeId);
    for (PBullet b : enemyBulletsInAir) {
      if (injuryCD == 0 && b.enemyDist.x > -24 && b.enemyDist.x < 24
        && b.enemyDist.y > -36 && b.enemyDist.y < 42) {
        injuryCD = maxInjuryCD;
        face = -1 * b.face; // When hit, let player face the bullet-coming direction
        vel.x = velHitX * face; // Hit physics
        vel.y = velHitY;
        b.isShot = false; // Bullet disappears
        HP--;

        //TODO Round end if HP == 0
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
    } else if (jumpable == 0) {  // If jump key is released and the player is in the air
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
    lastMoveFrame = frameCtr;
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

  void render() {
    // Injury invincible animation
    if (injuryCD > 0) {
      if (frameCtr % 4 > 1) {
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
      shootReadyFrame = frameCtr;
    }
    pushMatrix();
    if (frameCtr - shootReadyFrame < 4) {
      translate(-1 * recoilOffset * face, 0);
    }
    pistol.render(pos.x, pos.y);
    renderHand(pos.x, pos.y);
    popMatrix();

    renderBody(pos.x, pos.y, teeColor);
    renderEyes(pos.x, pos.y);
    renderHP();
  }

  void renderHP() {
    int offsetX = 10;
    int lx = 10 + offsetX;
    int rx = width-178-offsetX;
    int y = 10;
    int h = 18;
    int halfInnerH = (h-2)/2;

    fill(60);
    stroke(20);
    strokeWeight(2);
    if (teeId == 0) {
      rect(lx-1, y-1, maxHP*12+2, h); // black background

      fill(144, 242, 97); // shallow green layer
      noStroke();
      rect(lx, y, HP*12, h-2);

      fill(117, 191, 80); // dark green layer
      rect(lx, y+halfInnerH, HP*12, halfInnerH);
    } else {
      rect(rx-1, y-1, maxHP*12+2, h);

      fill(144, 242, 97);
      noStroke();
      rect(rx, y, HP*12, h-2);

      fill(117, 191, 80);
      rect(rx, y+halfInnerH, HP*12, halfInnerH);
    }
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

  void renderBody(float x, float y, color c) {
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
        if ((frameCtr - lastMoveFrame) > 300 && (frameCtr - lastMoveFrame) % 300 < 5) {
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
        if ((frameCtr - lastMoveFrame) > 300 && (frameCtr - lastMoveFrame) % 300 < 5) {
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
    // TODO need a keymap config
    if (pressJump) {
      text("Z", (72 + offsetX), terrain.posY + posY);
    }
    if (pressShoot) {
      text("X", (96 + offsetX), terrain.posY + posY);
    }
  }

  void showDebugInfo() {
    fill(20);
    noStroke();
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

    // Bullet positions
    PBullet b0 = pistol.bulletsInAir.peekFirst();
    text("bu0.x " + nf(b0 == null ? 0 : b0.pos.x, 1, 1), 175+offsetX, terrain.posY + 20);
    text("bu0.y " + nf(b0 == null ? 0 : b0.pos.y, 1, 1), 175+offsetX, terrain.posY + 35);

    PBullet b1 = null;
    if (pistol.bulletsInAir.size() > 1) {
      b1 = pistol.bulletsInAir.peekLast();
    }
    text("bu1.x " + nf(b1 == null ? 0 : b1.pos.x, 1, 1), 260+offsetX, terrain.posY + 20);
    text("bu1.y " + nf(b1 == null ? 0 : b1.pos.y, 1, 1), 260+offsetX, terrain.posY + 35);

    // Enemy bullet relative dists
    PBullet eb0 = null;
    if (enemyBulletsInAir != null) {
      eb0 = enemyBulletsInAir.peekFirst();
    }
    text("eb0.x " + nf(eb0 == null ? 0 : eb0.enemyDist.x, 1, 1), 175+offsetX, terrain.posY + 50);
    text("eb0.y " + nf(eb0 == null ? 0 : eb0.enemyDist.y, 1, 1), 175+offsetX, terrain.posY + 65);

    PBullet eb1 = null;
    if (enemyBulletsInAir != null && enemyBulletsInAir.size() > 1) {
      eb1 = enemyBulletsInAir.peekLast();
    }
    text("eb1.x " + nf(eb1 == null ? 0 : eb1.enemyDist.x, 1, 1), 260+offsetX, terrain.posY + 50);
    text("eb1.y " + nf(eb1 == null ? 0 : eb1.enemyDist.y, 1, 1), 260+offsetX, terrain.posY + 65);

    // Enemy bullet faces
    text("eb0.f " + (eb0 == null ? 0 : eb0.face), 175+offsetX, terrain.posY + 80);
    text("eb1.f " + (eb1 == null ? 0 : eb1.face), 260+offsetX, terrain.posY + 80);


    if (teeId == 0) {
      text("isInAir " + isInAir(), 10, terrain.posY + 150);
      text("frameCtr " + frameCtr, 10, terrain.posY + 165);
      text("lastMoveFrame " + lastMoveFrame, 10, terrain.posY + 180);
      text("shootReadyFrame " + shootReadyFrame, 10, terrain.posY + 195);
    }
  }

  //int colorAlpha(color e, int t) {
  //  return color(red(e), green(e), blue(e), (alpha(e) * t) / 255);
  //}
}
