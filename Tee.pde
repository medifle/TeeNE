class Tee {
  int teeId;
  
  PVector pos;
  PVector vel = new PVector(0, 0);

  int face;
  int size = 50;
  int HP = 14;

  boolean isBot = false;
  boolean pressLeft = false;
  boolean pressRight = false;
  boolean pressJump = false;
  boolean pressShoot = false;
  boolean prevPressShoot = false; // Only fire once when press and hold the pressShoot key

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
  PVector enemyDist;
  
  // NN should only know the number of bullets (implicitly) and their relative distances and faces
  // For distance
  // If only one bullet in screen, always use the first one in deque
  // If two bullets in screen, the first one in deque is the first fired
  ArrayDeque<PBullet> enemyBulletsInAir;

  // For drawing
  color teeColor;
  int lastMoveFrame = 0; // Used for blinking eyes, the last frame tee is idle
  // For recoil animation
  int shootReadyFrame = -99;
  int recoilOffset = 6;

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
    
  }
  
  void update() {
    move();
    pistol.shoot();
    pistol.bulletsMove();
  }
  
  void move() {
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
    if (newPosY > maxPosY) {
      pos.y = maxPosY; // Perfect landing
      vel.y = 0;
    } else {
      pos.y = newPosY; // If in the air, update the Y position
    }
    
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
    if (newPosX >= terrain.leftBoundary && newPosX <= terrain.rightBoundary) {
      pos.x = newPosX;
    } else if (newPosX < 10) {
      pos.x = terrain.leftBoundary;
    } else if (newPosX > terrain.rightBoundary) {
      pos.x = terrain.rightBoundary;
    }
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
    
    // recoil animation
    if (pistol.shootReady()) {
      shootReadyFrame = frameCtr;
    }
    pushMatrix();
    if (frameCtr - shootReadyFrame < 4) {
      translate(-1 * recoilOffset * face,0);
    }
    pistol.render(pos.x, pos.y);
    renderHand(pos.x, pos.y);
    popMatrix();

    renderBody(pos.x, pos.y, teeColor);
  }

  void renderBody(float x, float y, color c) {
    strokeWeight(2.5);
    stroke(c);
    
    if (teeId == 0) {
      fill(221,221,233);
    } else {
      fill(237,221,221);
    }
    
    ellipse(x, y, size, size);

    // eyes
    strokeWeight(1);
    stroke(0);
    fill(20);
    
    // blink every 5s when idle
    if ((frameCtr - lastMoveFrame) > 300 && (frameCtr - lastMoveFrame) % 300 < 5) {
      ellipse(x+(face == 1 ? 3 : -3), y-3, 7, 2);
      ellipse(x+(face == 1 ? 14 : -14), y-3, 7, 2);
    } else {
      ellipse(x+(face == 1 ? 3 : -3), y-3, 7, 14);
      ellipse(x+(face == 1 ? 14 : -14), y-3, 7, 14);
    }

    noFill();
  }
  
  void renderHand(float x, float y) {
    int ax = 25 * face;
    int bx = (abs(ax)+3)*face;
    int cx = ((abs(bx)+2))*face;
    int dx = ((abs(cx)-2))*face;
    int ex = ((abs(dx)-7))*face;
    
    strokeWeight(1.5);
    
    beginShape();
    fill(220);
    curveVertex(x+ax, y);
    
    curveVertex(x+ax, y);
    curveVertex(x+bx,  y+2);
    curveVertex(x+cx,  y+5);
    curveVertex(x+dx,  y+9);
    curveVertex(x+ex,  y+14);
    
    curveVertex(x+ex,  y+14);
    endShape();
  }

  void showDebugInfo() {
    fill(20);
    noStroke();
    textSize(12);
    
    if (teeId == 0) {
      text("pos.x " + nf(pos.x, 1, 2), 10, terrain.posY + 20);
      text("pos.y " + nf(pos.y, 1, 2), 10, terrain.posY + 35);
      text("vel.x " + nf(vel.x, 1, 2), 100, terrain.posY + 20);
      text("vel.y " + nf(vel.y, 1, 2), 100, terrain.posY + 35);
      
      text("shootable " + pistol.shootable, 180, terrain.posY + 50);
      
      PBullet b1 = pistol.ammuInAir.peekFirst();
      text("bullet0.x " + nf(b1 == null ? 0 : b1.pos.x, 1, 1), 180, terrain.posY + 20);
      text("bullet0.y " + nf(b1 == null ? 0 : b1.pos.y, 1, 1), 180, terrain.posY + 35);
      
      PBullet b2 = null;
      if (pistol.ammuInAir.size() > 1) {
        b2 = pistol.ammuInAir.peekLast();
      }
      text("bullet1.x " + nf(b2 == null ? 0 : b2.pos.x, 1, 1), 280, terrain.posY + 20);
      text("bullet1.y " + nf(b2 == null ? 0 : b2.pos.y, 1, 1), 280, terrain.posY + 35);
      
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
