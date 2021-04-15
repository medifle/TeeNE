class Brain {
  int score = 0;
  
  // initial Initialization stage
  // eval40  top 40 in Evaluation stage, 200 -> 40
  // eval8  top 8 in Evaluation stage, 40 -> 8
  // eval4  top 4 in Evaluation stage, 8 -> 4
  // eval2  top 2 in Evaluation stage, 4 -> 2
  // eval1  top 1 in Evaluation stage, 2 -> 1
  String label = "initial";
  
  NeuralNetwork nn;

  Brain() {
    this.nn = new NeuralNetwork(14, 14, 4);
  }

  NeuralNetwork getNN() {
    return nn;
  }
  
  void syncScore(int score) {
    this.score += score;
  }
  
  void clearStage() {
    this.score = 0;
  }
  
  void setLabel(String label) {
    this.label = label;
  }
  
  public String toString() {
    return label + "_" + score;
  }
}
