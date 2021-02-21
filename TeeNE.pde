//float unit = 1; // length unit

int frameCtr; // Frame count per round

Tee tee1, tee2;
Tees tees;

Terrain terrain;

boolean pause = false;


void setup() {
  pixelDensity(displayDensity());
  size(770, 550, P2D);

  terrain = new Terrain();

  tees = new Tees();
}

void draw() {
  frameCtr++;
  background(248);
  //background(25,25,77);
  //displayFrameRate();

  terrain.render();

  tees.update();
  tees.render();

  showDebugInfo();
}

void displayFrameRate() {
  textSize(14);
  text(frameRate, 2, 20);
}

void showDebugInfo() {
  tees.getPlayer().showDebugInfo();
}

void keyPressed() {
  teeControlKeymap(keyCode, true);
  gameKeymap(key);
}

void keyReleased() {
  teeControlKeymap(keyCode, false);
}

void teeControlKeymap(int k, boolean decision) {
  Tee playerTee = tees.getPlayer();
  if (k == LEFT) {
    playerTee.pressLeft = decision;
    playerTee.updateLastMoveFrame();
  } else if (k == RIGHT) {
    playerTee.pressRight = decision;
    playerTee.updateLastMoveFrame();
  } else if (k == 90) { // 'Z'
    playerTee.pressJump = decision;
    playerTee.updateLastMoveFrame();
  } else if (k == 88) { // 'X'
    playerTee.pressShoot = decision;
    playerTee.updateLastMoveFrame();
  }
}

void gameKeymap(char asciiKey) {
  switch(asciiKey) {
  case 'q':
    tees.getPlayer().cancelPressStatus();
    tees.switchPlayer();
    break;
  case 'v':
    //todo
    break;
  case 'p':
    if (pause) {
      loop();
    } else {
      noLoop();
    }
    pause = !pause;
    break;
  }
}
