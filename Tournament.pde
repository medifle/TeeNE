class Tournament {
  int roundFrameCtr = 0; // Frame count per round

  // 0 Not in training
  // 1 Initialization
  // 2 Evaluation
  // 3 Selection & Reproduction
  int stage = 0;

  int[] stageRounds = {0, 2000, 894, 360};
  int round = 0;
  int generation = 0; // 0 free play mode

  ArrayList<Brain> population;
  
  /* <group fight> */
  Brain[] brainGroup5 = new Brain[5];
  Brain[] brainGroup2 = new Brain[2];
  int brainGroup5Ctr = 0; // [1-10]
  int brainGroup2Ctr = 0; // [1-2]
  /* </group fight> */
  
  ArrayDeque<Brain> evalDeque; // Used in Evaluation stage

  // -1 tie
  // 0 teeId 0 wins
  // 1 teeId 1 wins
  int winner = -1;

  int maxRoundTime = 6;//test
  int roundTimeLeft = maxRoundTime;

  // -2 the current generation finished.
  // -1 ready to start the next generation
  // 0 the current round ended
  int roundEndCode = -1;

  int maxRoundGapTime = 120; // 120 frames, 2 seconds
  int roundGapTime = maxRoundGapTime;

  int skip = 0; // 0 no fastforward training, 1 otherwise

  Tournament() {
    population = new ArrayList<>();
  }

  void initNewRound() {
    roundFrameCtr = 0;
    roundTimeLeft = maxRoundTime;
    winner = -1;
    roundEndCode = -1;

    if (generation == 1) {
      stage = 1;
    } else if (generation > 1) {
      stage = 3;
    }

    



    //test
    //Tee tee0 = new Tee(0);
    //Brain b1 = new Brain();
    //Tee tee1 = new Tee(1, b1);
    //tees = new Tees(tee0, tee1);
  }

  Brain[] groupFight5(Brain[] group) {
    if (group.length != 5) throw new RuntimeException("Invalid group length.");
    if (brainGroup5Ctr < 1 || brainGroup5Ctr > 10) throw new RuntimeException("Invalid round counter.");
    
    Brain[] match = new Brain[2];
    int ctrMod = brainGroup5Ctr % 10;

    switch (ctrMod) {
    case 1:
      println("groupFight5: case 1");//test
      match[0] = group[0];
      match[1] = group[1];
      break;
    case 2:
      println("groupFight5: case 2");//test
      match[0] = group[2];
      match[1] = group[3];
      break;
    case 3:
      println("groupFight5: case 3");//test
      match[0] = group[4];
      match[1] = group[0];
      break;
    case 4:
      println("groupFight5: case 4");//test
      match[0] = group[1];
      match[1] = group[2];
      break;
    case 5:
      println("groupFight5: case 5");//test
      match[0] = group[3];
      match[1] = group[4];
      break;
    case 6:
      println("groupFight5: case 6");//test
      match[0] = group[0];
      match[1] = group[2];
      break;
    case 7:
      println("groupFight5: case 7");//test
      match[0] = group[1];
      match[1] = group[3];
      break;
    case 8:
      println("groupFight5: case 8");//test
      match[0] = group[2];
      match[1] = group[4];
      break;
    case 9:
      println("groupFight5: case 9");//test
      match[0] = group[3];
      match[1] = group[0];
      break;
    case 0:
      println("groupFight5: case 0");//test
      match[0] = group[4];
      match[1] = group[1];
      break;
    }

    return match;
  }

  Brain[] groupFight2(Brain[] group) {
    if (group.length != 2) throw new RuntimeException("Invalid group length.");
    if (brainGroup2Ctr < 1 || brainGroup2Ctr > 2) throw new RuntimeException("Invalid round counter.");

    Brain[] match = new Brain[2];
    int ctrMod = brainGroup2Ctr % 2;

    switch (ctrMod) {
    case 1:
      println("groupFight2: case 1");//test
      match[0] = group[0];
      match[1] = group[1];
      break;
    case 0:
      println("groupFight2: case 0");//test
      match[0] = group[1];
      match[1] = group[0];
      break;
    }

    return match;
  }

  void nextGen() {
    if (generation == 0) {
      round = 1;
      generation = 1;
    }

    initNewRound();
  }

  void update() {

    if (roundEndCode == 0) { // Round ended
      if (roundGapTime > 0) {
        roundGapTime--;
      } else if (roundGapTime == 0) {
        if (round > 0) {
          round++;
        }

        initNewRound();
      }
    } else if (roundEndCode == -1) { // Training
      roundFrameCtr++;
      roundTimeLeft = maxRoundTime - roundFrameCtr / 60;
      if (roundTimeLeft == 0) {
        endRound();
      }

      // If no fastforward, draw game background
      if (skip == 0) {
        background(248); //background(25,25,77);
        terrain.render();
      }

      // If game is in progress
      if (roundEndCode == -1) {
        //TODO fastforward
        tees.update();
      }

      // Show necessary game elements only when no fastforward training
      if (skip == 0) {
        tees.render();
        showRoundInfo();
        tees.showJoypad();
        tees.showDebugInfo();

        if (roundEndCode == 0) {
          showRoundResult();
        }
      }
    } else if (roundEndCode == -2) { // Generation finished.
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
    } else { // No winner, a tie
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
