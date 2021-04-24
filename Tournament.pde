class Tournament {
  int roundFrameCtr = 0; // Frame count per round

  int generation = 0; // 0 free play mode

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

  // -2 menu.
  //   When game starts, or
  //   When the current generation finished, go back to menu
  // -1 ready to start the next generation
  // 0 the current round ended
  int roundEndCode = -2;

  int availableId = 1; // Used to generate new brain name

  ArrayList<Brain> population;

  /* <group fight> */
  Brain[] fightGroup;
  int brainGroup5Ctr = 0; // effective range [1-10], 0 initial value
  int brainGroup2Ctr = 0; // effective range [1-2], 0 initial value
  /* </group fight> */

  String hyphen = "-";

  /* <stage 2> */
  ArrayDeque<Brain> evalDeque;
  Brain champion;
  int evalChampionRound = 494; // 40*10+8*10+4*2+2*2+1*2
  HashMap<String, int[]> benchmarkLog;
  /* </stage 2> */

  /* <stage 3> */
  ArrayList<Brain> nextPopulation;
  HashSet<String> chosenParentSet;
  ArrayList<Brain> tsPool; // Tournament selection candidate pool

  float mutationRate = 0.01;
  Function<Float, Float> randomGaussianMutate = (val) -> {
    if (random(1) < mutationRate) {
      float offset = randomGaussian() * 0.5; // 0.5 is arbitrarily chosen
      Log.d("offset " + offset);
      return val + offset;
    }
    return val;
  };
  /* </stage 3> */

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
  boolean autoNextGen = false; // true nonstop evolution

  /* <no-motion detection> */
  float[][] prevIns;
  int detectionGap = 60; // Frames
  /* </no-motion detection> */

  // Fight mode
  // A deepcopy of the champion after benchmark
  Brain enemyBrain;

  Tournament() {
    population = new ArrayList<>();
    prevIns = new float[tees.getSize()][14];
    evalDeque = new ArrayDeque<>();
    benchmarkLog = new HashMap<>();
    nextPopulation = new ArrayList<>();
    chosenParentSet= new HashSet<>();
    tsPool = new ArrayList<>();
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
          if (!evalDeque.isEmpty()) throw new RuntimeException("evalDeque not empty.");

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
        } else if (brainGroup2Ctr == 1) {
          fightGroup = popBrains(evalDeque, 2);
        }

        // Only one counter > 0 here
        Brain[] match = null;
        if (brainGroup5Ctr > 0) {
          match = groupFight5(fightGroup);
        } else if (brainGroup2Ctr > 0) {
          match = groupFight2(fightGroup);
        } else {
          throw new RuntimeException("Match error.");
        }

        Tee tee0 = new Tee(0, match[0]);
        Tee tee1 = new Tee(1, match[1]);
        tees = new Tees(tee0, tee1);
      } else {                // Stage 2.2 Benchmark
        if (brainGroup2Ctr == 0) {
          Log.i("start benchmark.");

          boolean isRemoveSuccess = population.remove(champion);
          if (!isRemoveSuccess || population.size() != 199) {
            throw new RuntimeException("Remove error.");
          }

          if (!evalDeque.isEmpty()) throw new RuntimeException("evalDeque not empty.");
          if (!benchmarkLog.isEmpty()) throw new RuntimeException("benchmarkLog not empty.");

          copyBrainsToDeque(population, evalDeque);
          brainGroup2Ctr = 1;
        }

        if (brainGroup2Ctr == 3) brainGroup2Ctr = 1;

        if (brainGroup2Ctr == 1) {
          Brain popedBrain = evalDeque.pop();
          fightGroup = new Brain[]{champion, popedBrain};
        }

        Brain[] match = groupFight2(fightGroup);
        Tee tee0 = new Tee(0, match[0]);
        Tee tee1 = new Tee(1, match[1]);
        tees = new Tees(tee0, tee1);
      }
    }

    if (stage == 3) {
      if (brainGroup2Ctr == 0) {
        Log.i("start stage 3.");

        if (!tsPool.isEmpty()) throw new RuntimeException("tsPool not empty.");

        passElites(20);
        brainGroup2Ctr = 1;
      }

      if (brainGroup2Ctr == 3) brainGroup2Ctr = 1;

      if (brainGroup2Ctr == 1) {
        Brain b0 = randomBrain(population);
        Brain b1 = randomBrain(population);
        while (b0.getName().equals(b1.getName())) {
          Log.d("ts: same parent collision " + b0.getName() + "-" + b1.getName());

          b1 = randomBrain(population);
        }

        fightGroup = new Brain[]{b0, b1};
        Log.d("fightGroup " + Arrays.toString(fightGroup));
      }

      Brain[] match = groupFight2(fightGroup);
      Tee tee0 = new Tee(0, match[0]);
      Tee tee1 = new Tee(1, match[1]);
      tees = new Tees(tee0, tee1);
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
      } else if (roundGapTime == 0) { // Prepare next step
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
          } else if (stage == 3) {
            if (tsPool.size() == 1) {
              Brain parent0 = tsPool.get(0);
              Brain parent1 = getGroupChampion(fightGroup);

              String candidatePair = getSortedPairKey(parent0.getName(), parent1.getName());
              if (!chosenParentSet.contains(candidatePair)) {
                chosenParentSet.add(candidatePair);
                promoteGroupChampion(fightGroup, tsPool);
              } else {
                Log.d("ts: parent pair collision. " + candidatePair + ".\n");
              }
            }

            if (tsPool.isEmpty()) promoteGroupChampion(fightGroup, tsPool);

            // Two parents selected, do crossover and mutation
            if (tsPool.size() == 2) {
              //Brain[] babies = crossover(tsPool.get(0), tsPool.get(1)); // 1-point
              Brain[] babies = crossover2(tsPool.get(0), tsPool.get(1));  // 2-point

              babies[0].getNN().mutate(randomGaussianMutate);
              babies[1].getNN().mutate(randomGaussianMutate);

              nextPopulation.add(babies[0]);
              nextPopulation.add(babies[1]);

              Log.d("babies " + Arrays.toString(babies) + " born from " + tsPool + ".\n");
              tsPool.clear();
            }
          }
        }

        if (stage == 4 && round == 2) { // Back to menu
          enemyBrain = null;
          stage = 0;
          round = 0;
          roundEndCode = -2;

          Log.i("population " + population + "\n");
        }

        if (stage == 2) {
          if (evalDeque.size() == 1 &&
            evalDeque.peekFirst().getLabel().equals("eval1")) { // Stage 2.1 ended

            brainGroup2Ctr = 0;
            fightGroup = null;
            clearPopulationScore();
            champion = evalDeque.pop();

            Log.i("population " + population + "\n");
          } else if (evalDeque.isEmpty() &&
            brainGroup2Ctr == 2 && champion != null) { // Stage 2.2 ended

            brainGroup2Ctr = 0;
            fightGroup = null;

            sortPopulation();
            insertChampion();
            champion = null;
            benchmarkLog.clear();
            clearPopulationScore();
            clearPopulationLabel();

            Log.i("population " + population + "\n");
            Log.i("gen " + generation + " finished.\n");

            if (generation % 100 == 0) tableUtil.saveData();
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

        if (stage == 3 && nextPopulation.size() == 200) {
          brainGroup2Ctr = 0;
          fightGroup = null;
          population = nextPopulation;
          // Do not use clear() which will empty population because they now have the same reference
          nextPopulation = new ArrayList<>();

          stage = 2; // stage 3 -> 2
          Log.i("population " + population + "\n");
          Log.i("stage 3 -> 2");
        }

        if (stage == 1 && round == stageRound[1]) { // Stage 1 ended
          // Reset
          brainGroup5Ctr = 0;
          fightGroup = null;
          clearPopulationScore();

          stage = 2; // stage 1 -> 2
          Log.i("population " + population + "\n");
          Log.i("stage 1 -> 2");
        }

        if (round > 0) round++;
        if (brainGroup5Ctr >= 1 && brainGroup5Ctr <= 10) brainGroup5Ctr++;
        if (brainGroup2Ctr >= 1 && brainGroup2Ctr <= 2) brainGroup2Ctr++;

        if (roundEndCode != -2) initNewRound();
      }
    } else if (roundEndCode == -1) { // In combat
      // If game is in progress, do combat, fastforward if enabled
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
      if (!debug) showTrainingInfo();

      // Show necessary game elements only when training is at normal speed
      if (!skip) {
        tees.render();
        showRoundInfo();
        tees.showJoypad();
        if (debug) tees.showDebugInfo();
        if (roundEndCode == 0) showRoundResult();
      }
    } else if (roundEndCode == -2) { // Generation finished, back to menu
      background(21, 26, 45);
      showTitle();
      showMenu();
    }
  }

  void nextGen() {
    availableId = 1;
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

  Brain getGroupChampion(Brain[] group) {
    Arrays.sort(group, Comparator.<Brain>comparingInt(a -> a.score).reversed());
    return group[0];
  }

  String generateName() {
    String name = generation + "#" + availableId;
    availableId++;
    return name;
  }

  // Push the group champion to the destination collection
  void promoteGroupChampion(Brain[] group, Collection<Brain> destination) {
    Brain top = getGroupChampion(group);
    top.clearScore();

    // Give the top a name by natural order
    if (stage == 1) {
      top.setName(generateName());
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

    if (evalDeque == destination) Log.d("evalDeque " + evalDeque + "\n");
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

    Log.d("pop" + size + " " + Arrays.toString(group));

    return group;
  }

  // Shallow copy, no overwrite
  void copyBrainsToDeque(ArrayList<Brain> popul, ArrayDeque<Brain> deque) {
    deque.addAll(popul);
  }

  // Shallow copy, no overwrite
  void shuffleBrainsToDeque(ArrayList<Brain> popul, ArrayDeque<Brain> deque) {
    ArrayList<Brain> al = new ArrayList<>(popul);
    Collections.shuffle(al);
    deque.addAll(al);
  }

  // Elitism
  // Pass top 10% of population directly to the next generation
  void passElites(int n) {
    if (!nextPopulation.isEmpty()) throw new RuntimeException("nextPopulation not empty.");

    nextPopulation.addAll(population.subList(0, n));
  }

  Brain randomBrain(ArrayList<Brain> al) {
    int index = int(random(al.size()));
    return al.get(index);
  }

  // Sort two strings lexicographically
  String getSortedPairKey(String bname0, String bname1) {
    if (bname0.compareTo(bname1) < 0) {
      return bname0 + hyphen + bname1;
    } else {
      return bname1 + hyphen + bname0;
    }
  }

  // Single-point crossover
  Brain[] crossover(Brain p0, Brain p1) {
    float[] parentChromosome0 = p0.getNN().toArray();
    float[] parentChromosome1 = p1.getNN().toArray();
    int chromosomeLength = parentChromosome0.length;

    float[] babyChromosome0 = new float[chromosomeLength];
    float[] babyChromosome1 = new float[chromosomeLength];

    int cutPoint = int(random(chromosomeLength));
    Log.d("cutPoint " + cutPoint);

    // Single point cut
    for (int i = 0; i < chromosomeLength; i++) {
      if (i <= cutPoint) {
        babyChromosome0[i] = parentChromosome1[i];
        babyChromosome1[i] = parentChromosome0[i];
      } else {
        babyChromosome0[i] = parentChromosome0[i];
        babyChromosome1[i] = parentChromosome1[i];
      }
    }

    Brain b0 = new Brain();
    b0.setName(generateName());
    b0.getNN().fromArray(babyChromosome0);

    Brain b1 = new Brain();
    b1.setName(generateName());
    b1.getNN().fromArray(babyChromosome1);

    return new Brain[]{b0, b1};
  }

  // Two-point crossover
  Brain[] crossover2(Brain p0, Brain p1) {
    float[] parentChromosome0 = p0.getNN().toArray();
    float[] parentChromosome1 = p1.getNN().toArray();
    int chromosomeLength = parentChromosome0.length;

    float[] babyChromosome0 = new float[chromosomeLength];
    float[] babyChromosome1 = new float[chromosomeLength];

    int randomIndex0 = int(random(chromosomeLength));
    int randomIndex1 = int(random(chromosomeLength));
    int cutPoint0 = min(randomIndex0, randomIndex1);
    int cutPoint1 = max(randomIndex0, randomIndex1);
    Log.d("cutPoint0 " + cutPoint0 + " " + "cutPoint1 " + cutPoint1);

    // Two-point cut
    for (int i = 0; i < chromosomeLength; i++) {
      if (i >= cutPoint0 && i <= cutPoint1) {
        babyChromosome0[i] = parentChromosome1[i];
        babyChromosome1[i] = parentChromosome0[i];
      } else {
        babyChromosome0[i] = parentChromosome0[i];
        babyChromosome1[i] = parentChromosome1[i];
      }
    }

    Brain b0 = new Brain();
    b0.setName(generateName());
    b0.getNN().fromArray(babyChromosome0);

    Brain b1 = new Brain();
    b1.setName(generateName());
    b1.getNN().fromArray(babyChromosome1);

    return new Brain[]{b0, b1};
  }

  void logBenchmark() {
    // Uniqueness guaranteed
    String hkey = fightGroup[0].getName() + hyphen + fightGroup[1].getName();
    int[] scores = new int[]{fightGroup[0].getScore(), fightGroup[1].getScore()};
    benchmarkLog.put(hkey, scores);
  }

  void sortPopulation() {
    Collections.sort(population, Comparator.<Brain>comparingInt(a -> a.score).reversed());
  }

  // population should be sorted in decreasing order by score before calling this method
  void insertChampion() {
    for (int i = 0; i < population.size(); i++) {
      String hkey = champion.getName() + hyphen + population.get(i).getName();
      int[] scores = benchmarkLog.get(hkey);
      Log.d("i " + i + ". " + "scores " + hkey + ": " + Arrays.toString(scores));

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
      match[0] = group[0];
      match[1] = group[1];
      break;
    case 2:
      match[0] = group[2];
      match[1] = group[3];
      break;
    case 3:
      match[0] = group[4];
      match[1] = group[0];
      break;
    case 4:
      match[0] = group[1];
      match[1] = group[2];
      break;
    case 5:
      match[0] = group[3];
      match[1] = group[4];
      break;
    case 6:
      match[0] = group[0];
      match[1] = group[2];
      break;
    case 7:
      match[0] = group[1];
      match[1] = group[3];
      break;
    case 8:
      match[0] = group[2];
      match[1] = group[4];
      break;
    case 9:
      match[0] = group[3];
      match[1] = group[0];
      break;
    case 0:
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
      match[0] = group[0];
      match[1] = group[1];
      break;
    case 0:
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
    if (winner > -1) { // Show winner
      int offsetX = 130;
      fill(60);
      textFont(FontHNMI);
      textSize(40);
      textAlign(CENTER, CENTER);
      if (winner == 0) {
        text("WINNER", offsetX, 60);
      } else if (winner == 1) {
        text("WINNER", width-offsetX, 60);
      }
    } else {           // No winner, a tie
      fill(70);
      textFont(FontHNMI);
      textSize(40);
      textAlign(CENTER, CENTER);
      text("DRAW", width/2, 100);
    }

    // Show K.O.
    if (tees.areKOEnd()) {
      fill(60);
      textFont(FontHNMI);
      textSize(90);
      textAlign(CENTER, CENTER);
      text("K.O.", 390, 200);
    }

    textAlign(LEFT, BASELINE); // Restore default setting
  }

  void showTitle() {
    fill(255);
    noStroke();
    textFont(FontMonoL);
    textSize(45);
    text("TeeNE", 10, 40);

    stroke(20); // Restore stroke
  }

  void showMenu() {
    fill(255); // 180,250,114, 109,222,187
    noStroke();
    textFont(FontMonoL);
    textSize(28);

    if (generation == 0) {
      text("[L] Load", 270, 230);
      text("[R] Free Play", 270, 280);
    } else if (generation > 0) {
      text("[E] Save", 270, 230);
      text("[F] Fight", 270, 280);
    }
    text("[N] Next Gen", 270, 330);
    text("Gen " + generation, 10, 540);

    stroke(20); // Restore stroke
  }

  void showTrainingInfo() {
    fill(20);
    noStroke();
    textFont(FontConsolas);
    textSize(14);

    int baseY = 25;
    int gapY = 17;
    text("Gen " + generation, 10, terrain.posY + baseY);
    text("Stage " + stage, 10, terrain.posY + baseY + 1*gapY);
    text("Round " + round, 10, terrain.posY + baseY + 2*gapY);
    text("Stage Round " + stageRound[stage], 10, terrain.posY + baseY + 3*gapY);
    text("Nonstop " + autoNextGen, 10, terrain.posY + baseY + 4*gapY);

    if (!skip) {
      tees.calcScore();
      text("score " + tees.get(0).score, 10, terrain.posY + 125);
      text("score " + tees.get(1).score, 690, terrain.posY + 125);
    }

    stroke(20); // Restore stroke
  }

  void endRound() {
    selectWinner();
    tees.syncScore();
    Log.d("endRound " + brainGroup5Ctr + " " + brainGroup2Ctr +
      " " + Arrays.toString(fightGroup));

    roundEndCode = 0;
    roundGapTime = (skip) ? 0 : maxRoundGapTime;
  }
}
