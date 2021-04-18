class Tournament {
  int roundFrameCtr = 0; // Frame count per round

  // 0  menu, free play mode
  //
  // <training>
  // 1  Initialization
  // 2  Evaluation
  // 3  Selection & Reproduction
  // </training>
  //
  // 4  Fight mode
  int stage = 0;

  int[] stageRound = {0, 2000, 892, 360, 2};

  int round = 0;
  int generation = 0; // 0 free play mode

  // -2 menu.
  //   When game starts, or
  //   When the current generation finished, go back to menu
  // -1 ready to start the next generation
  // 0 the current round ended
  int roundEndCode = -2;

  ArrayList<Brain> population;

  /* <group fight> */
  Brain[] fightGroup;
  int brainGroup5Ctr = 0; // effective range [1-10], 0 initial value
  int brainGroup2Ctr = 0; // effective range [1-2], 0 initial value
  /* </group fight> */

  /* <evaluation stage> */
  ArrayDeque<Brain> evalDeque;
  Brain champion;
  int evalChampionRound = 494; // 40*10+8*10+4*2+2*2+1*2
  HashMap<String, int[]> benchmarkLog;
  String benchmarkHyphen = "-";
  /* </evaluation stage> */

  // -1 tie
  // 0 teeId 0 wins
  // 1 teeId 1 wins
  int winner = -1;

  int maxRoundTime = 60;
  int roundTimeLeft = maxRoundTime;
  int maxRoundGapTime = 120; // 120 frames, 2 seconds
  int roundGapTime = maxRoundGapTime;

  boolean skip = false; // true fastforward training
  boolean skipOne = false; // true fastforward only 1 round
  boolean autoNextGen = false; // true continuous evolution

  /* <no-motion detection> */
  float[][] prevIns;
  int detectionGap = 60; // Frames
  /* </no-motion detection> */

  // Fight mode
  // A deepcopy of the population champion
  Brain enemyBrain;

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

    if (stage == 0) {
      tees = new Tees();
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
      if (champion == null) { // Stage 2.1 Get champion
        if (brainGroup5Ctr == 0 && brainGroup2Ctr == 0) {
          if (!evalDeque.isEmpty()) throw new RuntimeException("evalDeque error: not empty");

          shuffleBrainsToDeque(population, evalDeque);
          brainGroup5Ctr = 1;
        }

        if (brainGroup5Ctr == 11) brainGroup5Ctr = 1;
        if (brainGroup2Ctr == 3) brainGroup2Ctr = 1;

        if (brainGroup5Ctr == 1 || brainGroup2Ctr == 1) {
          String frontBrainLabel = evalDeque.peekFirst().getLabel();
          switch (frontBrainLabel) {
          case "init":
            brainGroup5Ctr = 1;
            brainGroup2Ctr = 0;
            break;
          case "eval40":
            brainGroup5Ctr = 1;
            brainGroup2Ctr = 0;
            break;
          case "eval8":
            brainGroup5Ctr = 0;
            brainGroup2Ctr = 1;
            break;
          case "eval4":
            brainGroup5Ctr = 0;
            brainGroup2Ctr = 1;
            break;
          case "eval2":
            brainGroup5Ctr = 0;
            brainGroup2Ctr = 1;
            break;
          default:
            throw new RuntimeException("Label error.");
          }
        }

        // Pop 5 or 2 brains
        if (brainGroup5Ctr == 1) {
          fightGroup = popBrains(evalDeque, 5);
          println("pop5 " + Arrays.toString(fightGroup));//test
        } else if (brainGroup2Ctr == 1) {
          fightGroup = popBrains(evalDeque, 2);
          println("pop2 " + Arrays.toString(fightGroup));//test
        }

        // Only one counter > 0 here
        Brain[] match = null;
        if (brainGroup5Ctr > 0) {
          match = groupFight5(fightGroup);
        } else if (brainGroup2Ctr > 0) {
          match = groupFight2(fightGroup);
        } else {
          throw new RuntimeException("Match error: should not reach here.");
        }

        Tee tee0 = new Tee(0, match[0]);
        Tee tee1 = new Tee(1, match[1]);
        tees = new Tees(tee0, tee1);
      } else {                // Stage 2.2 Benchmark
        if (brainGroup2Ctr == 0) {
          println("start benchmark.");//test

          boolean isRemoveSucess = population.remove(champion);
          if (!isRemoveSucess || population.size() != 199) {
            throw new RuntimeException("Remove error.");
          }

          if (!evalDeque.isEmpty()) throw new RuntimeException("evalDeque error: not empty.");
          if (!benchmarkLog.isEmpty()) throw new RuntimeException("benchmarkLog error: not empty.");

          copyBrainsToDeque(population, evalDeque);
          brainGroup2Ctr = 1;
        }

        if (brainGroup2Ctr == 3) brainGroup2Ctr = 1;

        if (brainGroup2Ctr == 1) {
          Brain popedBrain = evalDeque.pop();
          fightGroup = new Brain[]{champion, popedBrain};
          //println("\nbenchgroup " + Arrays.toString(fightGroup));//test
        }

        Brain[] match = groupFight2(fightGroup);
        Tee tee0 = new Tee(0, match[0]);
        Tee tee1 = new Tee(1, match[1]);
        tees = new Tees(tee0, tee1);
      }
    }

    if (stage == 3) {
      //TODO
    }

    if (stage == 4) {
      if (population.isEmpty()) throw new RuntimeException("population empty");

      enemyBrain = population.get(0).copy();
      tees = new Tees();

      int ctrMod = round % 2;
      switch (ctrMod) {
      case 1:
        tees.useBrain(1, enemyBrain);
        break;
      case 0:
        tees.useBrain(0, enemyBrain);
        tees.switchPlayer();
        break;
      default:
        throw new RuntimeException("ctrMod error.");
      }
    }
  }

  void update() {
    if (roundEndCode == 0) { // Round ended
      if (roundGapTime > 0) {
        roundGapTime--;
      } else if (roundGapTime == 0) {
        if (brainGroup5Ctr == 10) {
          if (stage == 1) {
            promoteGroupChampion(fightGroup, population);
          } else if (stage == 2) { // Stage 2.1
            promoteGroupChampion(fightGroup, evalDeque);
          }
        }
        if (brainGroup2Ctr == 2) {
          if (stage == 2) {
            if (champion == null) { // Stage 2.1
              promoteGroupChampion(fightGroup, evalDeque);
            } else {                // Stage 2.2
              logBenchmark();
              champion.clearScore();
            }
          }
        }

        if (stage == 4 && round == 2) { // Back to menu
          enemyBrain = null;
          stage = 0;
          round = 0;
          roundEndCode = -2;

          println("population " + population + "\n");//test
        }

        if (stage == 2) {
          if (round == (stageRound[1] + evalChampionRound)) { // Stage 2.1 ended
            if (evalDeque.peekFirst().getLabel() != "eval1") {
              throw new RuntimeException("Champion error.");
            }

            brainGroup2Ctr = 0;
            fightGroup = null;
            clearPopulationScore();
            champion = evalDeque.pop();

            println("population " + population + "\n");//test
          } else if (round == (stageRound[1] + stageRound[2])) { // Stage 2.2 ended
            brainGroup2Ctr = 0;
            fightGroup = null;
            evalDeque.clear();

            sortPopulation();
            insertChampion();
            champion = null;
            benchmarkLog.clear();
            clearPopulationScore();
            clearPopulationLabel();

            println("population " + population + "\n");//test
            println("champion " + champion);//test

            if (autoNextGen) { // Enter next generation
              nextGen();
            } else {           // Back to menu
              stage = 0;
              round = 0;
              roundEndCode = -2;
              skip = false;
            }
          }
        }

        if (stage == 1 && round == stageRound[1]) { // Stage 1 ended
          // Reset
          brainGroup5Ctr = 0;
          fightGroup = null;
          clearPopulationScore();

          stage = 2; // Enter stage 2
          println("population " + population + "\n");//test
          println("going to stage 2...");//test
        }

        if (round > 0) round++;
        if (brainGroup5Ctr >= 1 && brainGroup5Ctr <= 10) brainGroup5Ctr++;
        if (brainGroup2Ctr >= 1 && brainGroup2Ctr <= 2) brainGroup2Ctr++;

        if (roundEndCode != -2) initNewRound();
      }
    } else if (roundEndCode == -1) { // Training
      // If game is in progress, do training, fastforward if enabled
      while (roundEndCode == -1) {
        roundFrameCtr++;
        roundTimeLeft = maxRoundTime - roundFrameCtr / 60;
        if (roundTimeLeft == 0) {
          endRound();
        }

        if (roundEndCode == -1) {
          tees.update();
          detectNoMotion();
        }

        if (!skip) break;
      }

      if (skipOne) {
        skip = false;
        skipOne = false;
      }

      background(248);
      terrain.render();
      if (!debug) showTrainingStatus();

      // Show necessary game elements only when training is at normal speed
      if (!skip) {
        tees.render();
        showRoundInfo();
        tees.showJoypad();
        if (debug) tees.showDebugInfo();
        if (roundEndCode == 0) showRoundResult();
      }
    } else if (roundEndCode == -2) { // Generation finished, back to menu
      //TODO UI
      background(25, 25, 77);
    }
  }

  void nextGen() {
    round = 1;
    generation++;

    if (generation == 1) {
      stage = 1;
    } else if (generation > 1) {
      stage = 3;
    }

    initNewRound();
  }

  void freePlayMode(boolean flag) {
    if (flag) {
      roundEndCode = -1;
    } else {
      roundEndCode = -2;
    }
  }

  void fightMode() {
    round = 1;
    stage = 4;
    skip = false;

    initNewRound();
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

  // Push the group champion to the destination collection
  void promoteGroupChampion(Brain[] group, Collection<Brain> destination) {
    Arrays.sort(group, Comparator.<Brain>comparingInt(a -> a.score).reversed());
    Brain top = group[0];

    top.clearScore();

    // Give the top a name by natural order
    if (stage == 1) {
      String name = "#" + (population.size() + 1);
      top.setName(name);
    }

    // Update label for the promotion
    if (stage == 2) {
      String oldLabel = top.getLabel();
      switch (oldLabel) {
      case "init":
        top.setLabel("eval40");
        break;
      case "eval40":
        top.setLabel("eval8");
        break;
      case "eval8":
        top.setLabel("eval4");
        break;
      case "eval4":
        top.setLabel("eval2");
        break;
      case "eval2":
        top.setLabel("eval1");
        break;
      default:
        throw new RuntimeException("Label error.");
      }
    }

    destination.add(top);


    if (evalDeque == destination) println("evalDeque " + evalDeque + "\n");//test
  }

  void clearPopulationScore() {
    for (Brain b : population) {
      b.clearScore();
    }
  }

  void clearPopulationLabel() {
    for (Brain b : population) {
      b.clearLabel();
    }
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

  void shuffleBrainsToDeque(ArrayList<Brain> popul, ArrayDeque<Brain> deque) {
    ArrayList<Brain> al = new ArrayList<>(popul);
    Collections.shuffle(al);
    deque.addAll(al);
  }

  void logBenchmark() {
    // Uniqueness guaranteed
    String hkey = fightGroup[0].getName() + benchmarkHyphen + fightGroup[1].getName();
    int[] scores = new int[]{fightGroup[0].getScore(), fightGroup[1].getScore()};
    benchmarkLog.put(hkey, scores);
  }

  void sortPopulation() {
    Collections.sort(population, Comparator.<Brain>comparingInt(a -> a.score).reversed());
  }

  // population should be sorted in decreasing order by score before calling this method
  void insertChampion() {
    for (int i = 0; i < population.size(); i++) {
      String hkey = champion.getName() + benchmarkHyphen + population.get(i).getName();
      int[] scores = benchmarkLog.get(hkey);
      println("i " + i + ". " + "scores " + Arrays.toString(scores));//test

      if (scores[0] >= scores[1]) {
        population.add(i, champion);
        break;
      }
    }
  }

  Brain[] groupFight5(Brain[] group) {
    if (group.length != 5) throw new RuntimeException("Invalid group length.");
    if (brainGroup5Ctr < 1 || brainGroup5Ctr > 10) {
      throw new RuntimeException("Invalid round counter.");
    }

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
    default:
      throw new RuntimeException("ctrMod error.");
    }

    return match;
  }

  Brain[] groupFight2(Brain[] group) {
    if (group.length != 2) throw new RuntimeException("Invalid group length.");
    if (brainGroup2Ctr < 1 || brainGroup2Ctr > 2) {
      throw new RuntimeException("Invalid round counter.");
    }

    Brain[] match = new Brain[2];
    int ctrMod = brainGroup2Ctr % 2;
    switch (ctrMod) {
    case 1:
      //println("groupFight2: case 1");//test
      match[0] = group[0];
      match[1] = group[1];
      break;
    case 0:
      //println("groupFight2: case 0");//test
      match[0] = group[1];
      match[1] = group[0];
      break;
    default:
      throw new RuntimeException("ctrMod error.");
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
    textSize(14);

    int baseY = 25;
    int gapY = 17;
    text("Gen " + generation, 10, terrain.posY + baseY);
    text("Stage " + stage, 10, terrain.posY + baseY + 1*gapY);
    text("Round " + round, 10, terrain.posY + baseY + 2*gapY);
    text("Stage Round " + stageRound[stage], 10, terrain.posY + baseY + 3*gapY);
    text("Auto NextGen " + autoNextGen, 10, terrain.posY + baseY + 4*gapY);

    if (!skip) {
      tees.calcScore();
      text("score " + tees.get(0).score, 10, terrain.posY + 125);
      text("score " + tees.get(1).score, 700, terrain.posY + 125);
    }

    stroke(20); // Restore stroke
  }

  void endRound() {
    selectWinner();
    tees.syncScore();
    println("endRound " + Arrays.toString(fightGroup));//test

    roundEndCode = 0;
    roundGapTime = (skip) ? 0 : maxRoundGapTime;
  }
}
