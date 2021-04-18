//float unit = 1; // length unit

boolean pause = false;
boolean debug = false;

Terrain terrain;
Tee tee1, tee2;
Tees tees;

Tournament tournament;
TableUtil tableUtil;

PFont FontSansSerif, FontKO;


void setup() {
  pixelDensity(displayDensity());
  size(770, 550, P2D);
  // loadFont to display better quality (but not perfect) in P2D mode
  FontSansSerif = loadFont("SansSerif-60.vlw");
  // createFont to avoid loadFont large vlw font and ground disappearing bug when rendered
  FontKO = createFont("HelveticaNeue-MediumItalic", 90);

  terrain = new Terrain();
  tees = new Tees();
  tournament = new Tournament();
  tableUtil = new TableUtil(tournament);
}

void draw() {
  //displayFrameRate();

  tournament.update();
}

void displayFrameRate() {
  textSize(12);
  text(frameRate, 0, 20);
}

void keyPressed() {
  teeControlKeymap(keyCode, true);
  gameKeymap(key);
}

void keyReleased() {
  teeControlKeymap(keyCode, false);
}

void teeControlKeymap(int k, boolean decision) {
  Tee playerTee = tees.getHumanPlayer();
  if (playerTee.brainControl) return;

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
  case 'q': // Switch player
    tees.getHumanPlayer().cancelPressStatus();
    tees.switchPlayer();
    break;
  case 'v': // Fastforward training
    tournament.skip = !tournament.skip;
    break;
  case 's': // Fastforward one round
    tournament.skip = true;
    tournament.skipOne = true;
    break;
  case 'g': // Continuous evolution
    tournament.autoNextGen = !tournament.autoNextGen;
    break;
  case 'n': // Start next generation
    if (tournament.roundEndCode == -2) {
      tournament.nextGen();
    }
    break;
  case 'p': // Pause
    if (pause) {
      loop();
    } else {
      noLoop();
    }
    pause = !pause;
    break;
  case 'r': // Free play mode
    if (tournament.roundEndCode == -2 && tournament.generation == 0) {
      tournament.freePlayMode(true);
    }
    break;
  case 'b': // Back to menu from free play mode
    if (tournament.roundEndCode == -1 && tournament.generation == 0) {
      tournament.freePlayMode(false);
    }
    break;
  case 'f': // Fight mode: human vs. AI
    if (tournament.roundEndCode == -2 && tournament.generation > 0) {
      tournament.fightMode();
    }
    break;
  case 'e': // Save population
    if (tournament.roundEndCode == -2 && tournament.generation > 0) {
      tableUtil.saveData();
    }
    break;
  case 'l': // Load population
    //TODO
    if (tournament.roundEndCode == -2 && tournament.generation == 0) {
      tableUtil.loadData();
    }
    break;
  case 'd': // Toggle debug info
    if (tournament.roundEndCode == -1) {
      debug = !debug;
    }
    break;
  }
}
