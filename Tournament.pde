class Tournament {
  int roundFrameCtr = 0; // Frame count per round

  // 0 Not in training
  // 1 Initialization
  // 2 Evaluation
  // 3 Selection & Reproduction
  int stage = 0;

  int[] stageRound = {0, 2000, 894, 360};
  int round = 0;
  int generation = 0; // 0 free play mode

  ArrayList<Brain> population;

  /* <group fight> */
  Brain[] fightGroup;
  int brainGroup5Ctr = 0; // effective range [1-10], 0 initial value
  int brainGroup2Ctr = 0; // effective range [1-2], 0 initial value
  /* </group fight> */

  /* <evaluation stage> */
  ArrayDeque<Brain> evalDeque;
  Brain champion;
  HashMap<String, Integer> benchmarkLog;
  /* </evaluation stage> */

  // -1 tie
  // 0 teeId 0 wins
  // 1 teeId 1 wins
  int winner = -1;

  int maxRoundTime = 60;
  int roundTimeLeft = maxRoundTime;

  // -2 the current generation finished.
  // -1 ready to start the next generation
  // 0 the current round ended
  int roundEndCode = -2;

  int maxRoundGapTime = 120; // 120 frames, 2 seconds
  int roundGapTime = maxRoundGapTime;

  int skip = 0; // 0 no fastforward training, 1 otherwise

  /* <no-motion detection> */
  float[][] prevIns;
  int detectionGap = 60; // Frames
  /* </no-motion detection> */

  Tournament() {
    population = new ArrayList<>();
    prevIns = new float[tees.getSize()][14];
    evalDeque = new ArrayDeque<>();
    benchmarkLog = new HashMap<>();
  }

  void initNewRound() {
    roundFrameCtr = 0;
    winner = -1;
    roundTimeLeft = maxRoundTime;
    roundEndCode = -1;

    if (generation == 0) {
      tees = new Tees();
    } else if (generation == 1) {
      if (round == 1) {
        stage = 1;
      }
    } else if (generation > 1) {
      // TODO
    }

    if (stage == 1) {
      if (brainGroup5Ctr == 0 || brainGroup5Ctr == 11) { // groupFight5 reset
        brainGroup5Ctr = 1;
      }

      if (brainGroup5Ctr == 1) {
        fightGroup = getRandomBrains(5);
      }

      Brain[] match = groupFight5(fightGroup);
      Tee tee0 = new Tee(0, match[0]);
      Tee tee1 = new Tee(1, match[1]);
      tees = new Tees(tee0, tee1);
    }

    if (stage == 2) {
      //if (champion == null) {
      //  if (fightGroup == null) {
      //    println("stage 2 starts.");
      //    if (!evalDeque.isEmpty()) throw new RuntimeException("evalDeque should be empty at the start");
      //  }


      //  copyBrainsToDeque(population, evalDeque);
      //  String frontBrainLabel = evalDeque.peekFirst().getLabel();
      //  switch (frontBrainLabel) {
      //  case "initial":
      //    brainGroup5Ctr = 1;
      //    break;
      //  case "eval40":
      //    brainGroup5Ctr = 1;
      //    break;
      //  case "eval8":
      //    brainGroup2Ctr = 1;
      //    break;
      //  case "eval4":
      //    brainGroup2Ctr = 1;
      //    break;
      //  case "eval2":
      //    brainGroup2Ctr = 1;
      //    break;
      //  }

      //  // pop 5 or 2 brains
      //  Brain[] match = null;
      //  if (brainGroup5Ctr == 1) {
      //    fightGroup = popBrains(evalDeque, 5);
      //    match = groupFight5(fightGroup);
      //  } else if (brainGroup2Ctr == 1) {
      //    fightGroup = popBrains(evalDeque, 2);
      //    match = groupFight2(fightGroup);
      //  } else {
      //    throw new RuntimeException("Should not reach here.");
      //  }

      //  Tee tee0 = new Tee(0, match[0]);
      //  Tee tee1 = new Tee(1, match[1]);
      //  tees = new Tees(tee0, tee1);
      //} else {
      //  //TODO benchmark
      //}
    }
  }

  void update() {
    if (roundEndCode == 0) { // Round ended
      if (roundGapTime > 0) {
        roundGapTime--;
      } else if (roundGapTime == 0) {
        if (brainGroup5Ctr == 10) {
          promoteGroupChampion(fightGroup, population);
        }
        if (brainGroup2Ctr == 2) {
          promoteGroupChampion(fightGroup, evalDeque);
        }

        if (generation == 1) {
          if (stage == 1 && round == stageRound[stage]) {
            // Reset
            brainGroup5Ctr = 0;
            fightGroup = null;

            stage = 2; // Enter stage 2
            println("going to stage 2...");//test
          }
        }

        if (round > 0) round++;
        if (brainGroup5Ctr >= 1 && brainGroup5Ctr <= 10) brainGroup5Ctr++;
        if (brainGroup2Ctr >= 1 && brainGroup2Ctr <= 2) brainGroup2Ctr++;


        initNewRound();
      }
    } else if (roundEndCode == -1) { // Training
      // If game is in progress, do training
      // fastforward training if skip != 0
      while (roundEndCode == -1) {
        roundFrameCtr++;
        roundTimeLeft = maxRoundTime - roundFrameCtr / 60;
        if (roundTimeLeft == 0) {
          endRound();
        }

        if (roundEndCode == -1) {
          tees.update();
          //detectNoMotion();
        }

        if (skip == 0) break;
      }

      background(248);
      terrain.render();
      showTrainingStatus();

      // Show necessary game elements only when no fastforward training
      if (skip == 0) {
        tees.render();
        showRoundInfo();
        tees.showJoypad();
        if (debug) tees.showDebugInfo();
        if (roundEndCode == 0) showRoundResult();
      }
    } else if (roundEndCode == -2) { // Generation finished.
      //TODO
    }
  }

  void detectNoMotion() {
    if (roundFrameCtr % detectionGap == 0 && tees.areBrainControl()) {
      float[][] ins = prepareIns();

      if (isInsEqual(ins)) {
        endRound();
      } else {
        prevIns = ins;
      }
    }
  }

  // Prepare two tees input data
  float[][] prepareIns() {
    float[] in0 = tees.get(0).prepareInput();
    float[] in1 = tees.get(1).prepareInput();
    float[][] ins = new float[2][14];
    ins[0] = in0;
    ins[1] = in1;

    return ins;
  }

  // Compare two tees input data
  // true if they are deep equal, false otherwise
  boolean isInsEqual(float[][] ins) {
    for (int i = 0; i < tees.getSize(); i++) {
      for (int j = 0; j < 14; j++) {
        if (prevIns[i][j] != ins[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  // Add group champion to population
  void promoteGroupChampion(Brain[] group, Collection<Brain> destination) {
    Arrays.sort(group, Comparator.<Brain>comparingInt(a -> a.score));
    destination.add(group[group.length - 1]);


    if (evalDeque == destination) println("evalDeque: " + evalDeque + "\n");//test
  }

  Brain[] getRandomBrains(int size) {
    Brain[] group = new Brain[size];
    for (int i = 0; i < size; i++) {
      group[i] = new Brain();
    }
    return group;
  }

  Brain[] popBrains(ArrayDeque<Brain> deque, int size) {
    if (deque.size() < size) throw new RuntimeException("Invalid size.");

    Brain[] group = new Brain[size];
    for (int i = 0; i < size; i++) {
      group[i] = deque.pop();
    }
    return group;
  }

  // Shallow copy, only copy brain reference
  void copyBrainsToDeque(ArrayList<Brain> popul, ArrayDeque<Brain> deque) {
    deque.addAll(popul);
  }


  void nextGen() {
    round = 1;
    generation++;

    initNewRound();
  }

  Brain[] groupFight5(Brain[] group) {
    if (group.length != 5) throw new RuntimeException("Invalid group length.");
    if (brainGroup5Ctr < 1 || brainGroup5Ctr > 10) throw new RuntimeException("Invalid round counter.");

    Brain[] match = new Brain[2];
    int ctrMod = brainGroup5Ctr % 10;

    switch (ctrMod) {
    case 1:
      //println("groupFight5: case 1");//test
      match[0] = group[0];
      match[1] = group[1];
      break;
    case 2:
      //println("groupFight5: case 2");//test
      match[0] = group[2];
      match[1] = group[3];
      break;
    case 3:
      //println("groupFight5: case 3");//test
      match[0] = group[4];
      match[1] = group[0];
      break;
    case 4:
      //println("groupFight5: case 4");//test
      match[0] = group[1];
      match[1] = group[2];
      break;
    case 5:
      //println("groupFight5: case 5");//test
      match[0] = group[3];
      match[1] = group[4];
      break;
    case 6:
      //println("groupFight5: case 6");//test
      match[0] = group[0];
      match[1] = group[2];
      break;
    case 7:
      //println("groupFight5: case 7");//test
      match[0] = group[1];
      match[1] = group[3];
      break;
    case 8:
      //println("groupFight5: case 8");//test
      match[0] = group[2];
      match[1] = group[4];
      break;
    case 9:
      //println("groupFight5: case 9");//test
      match[0] = group[3];
      match[1] = group[0];
      break;
    case 0:
      //println("groupFight5: case 0");//test
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
    if (tees.areKOEnd()) {
      fill(60);
      textFont(FontKO);
      textSize(90);
      textAlign(CENTER, CENTER);
      text("K.O.", 390, 200);
    }

    textAlign(LEFT, BASELINE); // Restore default setting
  }

  void showTrainingStatus() {
    fill(20);
    noStroke();
    textFont(FontSansSerif);
    textSize(12);

    text("Gen " + generation, 10, terrain.posY + 20);
    text("Stage " + stage, 10, terrain.posY + 35);
    text("Round " + round, 10, terrain.posY + 50);
    text("Stage Round " + stageRound[stage], 10, terrain.posY + 65);

    stroke(20); // Restore stroke
  }

  void endRound() {
    selectWinner();
    tees.syncScore();
    //println(Arrays.toString(fightGroup));//test

    roundEndCode = 0;
    roundGapTime = (skip == 0) ? maxRoundGapTime : 0;
  }
}
