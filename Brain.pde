class Brain {
  int score = 0;

  String name = "#0";

  // init Initialization stage
  // eval40  top 40 in Evaluation stage, 200 -> 40
  // eval8  top 8 in Evaluation stage, 40 -> 8
  // eval4  top 4 in Evaluation stage, 8 -> 4
  // eval2  top 2 in Evaluation stage, 4 -> 2
  // eval1  top 1 in Evaluation stage, 2 -> 1
  String label = "init";

  NeuralNetwork nn;

  Brain() {
    this.nn = new NeuralNetwork(14, 14, 4);
  }

  NeuralNetwork getNN() {
    return nn;
  }

  int getScore() {
    return this.score;
  }

  void syncScore(int score) {
    this.score += score; // Accumulate score
  }

  void clearScore() {
    this.score = 0;
  }

  void setName(String name) {
    this.name = name;
  }

  String getName() {
    return this.name;
  }

  void setLabel(String label) {
    this.label = label;
  }

  String getLabel() {
    return this.label;
  }

  public String toString() {
    return name + "_" + label + "_" + score;
  }
}
