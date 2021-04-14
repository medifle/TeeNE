class Brain {
  int score = 0;
  String name = "unknown";
  boolean alive = true;
  NeuralNetwork nn;

  Brain() {
    this.nn = new NeuralNetwork(14, 14, 4);
  }

  NeuralNetwork getNN() {
    return nn;
  }
}
