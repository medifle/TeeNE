class Brain {
  String name = "#0";

  NeuralNetwork nn;

  int score = 0;

  // init    Initialization stage
  // eval40  top 40 in Evaluation stage, 200 -> 40
  // eval8   top 8 in Evaluation stage, 40 -> 8
  // eval4   top 4 in Evaluation stage, 8 -> 4
  // eval2   top 2 in Evaluation stage, 4 -> 2
  // eval1   top 1 in Evaluation stage, 2 -> 1
  String label = "init";

  Brain() {
    this.nn = new NeuralNetwork(14, 14, 4);
  }

  Brain(Brain b) {
    this.score = b.score;
    this.name = b.name;
    this.label = b.label;
    this.nn = b.nn.copy();
  }

  Brain copy() {
    return new Brain(this);
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

  String getName() {
    return this.name;
  }

  void setName(String name) {
    this.name = name;
  }

  String getLabel() {
    return this.label;
  }

  void setLabel(String label) {
    this.label = label;
  }

  void clearLabel() {
    this.label = "init";
  }


  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    Brain b = (Brain) o;
    return name.equals(b.name) &&
      nn.equals(b.nn) &&
      score == b.score &&
      label.equals(b.label);
  }

  public String toString() {
    return name + "_" + label + "_" + score;
  }
}
