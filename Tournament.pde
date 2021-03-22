class Tournament {
  int frameCtr = 0; // Frame count per round

  int stage;
  int generation = 0; // 0 means free play mode
  int winner = -1; // -1 means a tie by default
  int round = 0;
  int roundTotal = 0; // The running total of current generation rounds
  int maxRoundTime = 60;
  int roundTimeLeft = maxRoundTime;


  // -2 the current generation finished.
  // -1 ready to start the next generation
  // 0 the current round ended
  int roundEndCode = -1;

  int maxRoundGapTime = 120;
  int roundGapTime = maxRoundGapTime;

  int skip = 0;

  Tournament() { // Brain?
  }

  void init() {
    frameCtr = 0;
    roundTimeLeft = maxRoundTime;

    //if (generation > 0) {
    //  //stage ?
    //}

    winner = -1;
    roundEndCode = -1;
    tees = new Tees();
  }

  void nextGen() {
    //TODO data clean?

    init();
  }

  void update() {

    if (roundEndCode == 0) {
      if (roundGapTime > 0) { // Display round results for 2s
        roundGapTime--;
      } else if (roundGapTime == 0) {
        if (round > 0) {
          round++;
          roundTotal++;
        }

        init();
      }
    } else if (roundEndCode == -1) {
      frameCtr++;

      // If no fastforward, draw game background
      if (skip == 0) {
        background(248); //background(25,25,77);
        terrain.render();
      }

      //TODO fastforward
      tees.update();

      // If roundEndCode is the same, both tees are alive
      // Check if round is timeout
      if (roundEndCode == -1) {
        roundTimeLeft = maxRoundTime - frameCtr / 60;
        if (roundTimeLeft == 0) {
          endRound();
        }
      }

      if (skip == 0) {
        tees.render();
        showRoundInfo();
        tees.showJoypad();
        tees.showDebugInfo();

        if (roundEndCode == 0) {
          showRoundResult();
        }
      }
    } else if (roundEndCode == -2) {
      //TODO
    }
  }

  // Return teeId if >= 0
  //        -1    if tie
  void selectWinner() {
    if (tees.get(0).HP < tees.get(1).HP) {
      winner = 1;
    } else if (tees.get(0).HP > tees.get(1).HP) {
      winner = 0;
    } else {
      winner = -1;
    }
  }

  void showRoundInfo() {
    fill(40);
    textFont(FontSansSerif);

    textSize(18);
    textAlign(CENTER, CENTER);
    text("Round " + round, 385, 15);

    textSize(36);
    text(roundTimeLeft, 385, 45);

    textAlign(LEFT, BASELINE); // Restore default setting
  }

  void showRoundResult() {
    // Show winner
    if (winner > -1) {
      int offsetX = 130;
      fill(60);
      textFont(FontKO);
      textSize(40);
      textAlign(CENTER, CENTER);
      if (winner == 0) {
        text("WINNER", offsetX, 60);
      } else if (winner == 1) {
        text("WINNER", width-offsetX, 60);
      }
    } else { // A draw
      fill(70);
      textFont(FontKO);
      textSize(40);
      textAlign(CENTER, CENTER);
      text("DRAW", width/2, 100);
    }

    // Show K.O.
    if (tees.isKOEnd()) {
      fill(60);
      textFont(FontKO);
      textSize(90);
      textAlign(CENTER, CENTER);
      text("K.O.", 390, 200);
    }

    textAlign(LEFT, BASELINE); // Restore default setting
  }

  void endRound() {
    selectWinner();
    tees.calcScore();

    roundEndCode = 0;
    roundGapTime = maxRoundGapTime;
  }
}
