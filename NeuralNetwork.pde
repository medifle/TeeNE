// 2-layer Feedforward Neural Network

import java.util.function.Function;

class NeuralNetwork {
  int inputSize;
  int hiddenSize;
  int outputSize;

  Matrix weightsIH; // Weights between input layer and hidden layer
  Matrix biasH; // Bias for hidden layer
  Matrix weightsHO; // Weights between hidden layer and output layer
  Matrix biasO; // Bias for output layer

  // Activation functions
  Function<Float, Float> ReLU = (val) -> Math.max(0, val);
  Function<Float, Float> Sigmoid = (val) -> 1 / (1 + (float)Math.exp(-val));
  Function<Float, Float> Tanh = (val) -> 2 / (1 + (float)Math.exp(-2*val)) - 1;
  Function<Float, Float> Identity = (val) -> val;

  NeuralNetwork(int inputSize, int hiddenSize, int outputSize) {
    this.inputSize = inputSize;
    this.hiddenSize = hiddenSize;
    this.outputSize = outputSize;

    this.weightsIH = new Matrix(hiddenSize, inputSize);
    this.biasH = new Matrix(hiddenSize, 1);
    this.weightsHO = new Matrix(outputSize, hiddenSize);
    this.biasO = new Matrix(outputSize, 1);

    this.weightsIH.randomize();
    this.biasH.randomize();
    this.weightsHO.randomize();
    this.biasO.randomize();
  }

  NeuralNetwork(NeuralNetwork nn) {
    this.inputSize = nn.inputSize;
    this.hiddenSize = nn.hiddenSize;
    this.outputSize = nn.outputSize;

    this.weightsIH = nn.weightsIH.copy();
    this.biasH = nn.biasH.copy();
    this.weightsHO = nn.weightsHO.copy();
    this.biasO = nn.biasO.copy();
  }

  float[] feedforward(float[] inputArray) {
    // Calculate the hidden layer activations
    Matrix I = new Matrix(0, 0).fromInputArray(inputArray);
    Matrix H = weightsIH.multiply(I)
      .add(biasH)
      .map(ReLU); // Apply activation function

    // Calculate the output layer activations
    Matrix O = weightsHO.multiply(H).add(biasO); // No activation function for output layer
    return O.toArray();
  }

  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    NeuralNetwork nn = (NeuralNetwork) o;
    return inputSize == nn.inputSize &&
      hiddenSize == nn.hiddenSize &&
      outputSize == nn.outputSize &&
      weightsIH.equals(nn.weightsIH) &&
      biasH.equals(nn.biasH) &&
      weightsHO.equals(nn.weightsHO) &&
      biasO.equals(nn.biasO);
  }

  // For neuroevolution
  int size() {
    return hiddenSize*inputSize + inputSize + outputSize*hiddenSize + outputSize;
  }

  // Export chromosome
  float[] toArray() {
    float[] chromosome = new float[size()];

    float[] flatWeightsIH = this.weightsIH.toArray();
    float[] flatBiasH = this.biasH.toArray();
    float[] flatweightsHO = this.weightsHO.toArray();
    float[] flatBiasO = this.biasO.toArray();

    int destPos1 = 0;
    int destPos2 = destPos1 + flatWeightsIH.length;
    int destPos3 = destPos2 + flatBiasH.length;
    int destPos4 = destPos3 + flatweightsHO.length;

    System.arraycopy(flatWeightsIH, 0, chromosome, destPos1, flatWeightsIH.length);
    System.arraycopy(flatBiasH, 0, chromosome, destPos2, flatBiasH.length);
    System.arraycopy(flatweightsHO, 0, chromosome, destPos3, flatweightsHO.length);
    System.arraycopy(flatBiasO, 0, chromosome, destPos4, flatBiasO.length);

    return chromosome;
  }

  // Import chromosome
  void fromArray(float[] chromosome) {
    float[] flatWeightsIH = new float[hiddenSize*inputSize];
    float[] flatBiasH = new float[hiddenSize];
    float[] flatWeightsHO = new float[outputSize*hiddenSize];
    float[] flatBiasO = new float[outputSize];

    int srcPos1 = 0;
    int srcPos2 = srcPos1 + flatWeightsIH.length;
    int srcPos3 = srcPos2 + flatBiasH.length;
    int srcPos4 = srcPos3 + flatWeightsHO.length;

    System.arraycopy(chromosome, srcPos1, flatWeightsIH, 0, flatWeightsIH.length);
    System.arraycopy(chromosome, srcPos2, flatBiasH, 0, flatBiasH.length);
    System.arraycopy(chromosome, srcPos3, flatWeightsHO, 0, flatWeightsHO.length);
    System.arraycopy(chromosome, srcPos4, flatBiasO, 0, flatBiasO.length);

    this.weightsIH = this.weightsIH.fromArray(flatWeightsIH);
    this.biasH = this.biasH.fromArray(flatBiasH);
    this.weightsHO = this.weightsHO.fromArray(flatWeightsHO);
    this.biasO = this.biasO.fromArray(flatBiasO);
  }

  NeuralNetwork copy() {
    return new NeuralNetwork(this);
  }

  void mutate(Function<Float, Float> func) {
    this.weightsIH.selfMap(func);
    this.biasH.selfMap(func);
    this.weightsHO.selfMap(func);
    this.biasO.selfMap(func);
  }
}
