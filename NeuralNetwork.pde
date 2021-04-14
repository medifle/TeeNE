// 2-layer Feedforward Neural Network

import java.util.function.Function;

class NeuralNetwork {
  int inputSize;
  int hiddenSize;
  int outputSize;

  Matrix weightsIH; // Weights between input layer and hidden layer
  Matrix weightsHO; // Weights between hidden layer and output layer

  // Use separate bias matrix, might be easier instead of incorporating into weights matrix
  Matrix biasH; // Bias for hidden layer
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
    this.weightsHO = new Matrix(outputSize, hiddenSize);
    this.weightsIH.randomize();
    this.weightsHO.randomize();

    this.biasH = new Matrix(hiddenSize, 1);
    this.biasO = new Matrix(outputSize, 1);
    this.biasH.randomize();
    this.biasO.randomize();
  }

  NeuralNetwork(NeuralNetwork nn) {
    this.inputSize = nn.inputSize;
    this.hiddenSize = nn.hiddenSize;
    this.outputSize = nn.outputSize;

    this.weightsIH = nn.weightsIH.copy();
    this.weightsHO = nn.weightsHO.copy();

    this.biasH = nn.biasH.copy();
    this.biasO = nn.biasO.copy();
  }

  float[] feedforward(float[] inputArray) {
    // Calculate the hidden layer activations
    Matrix I = new Matrix(0, 0).fromArray(inputArray);
    Matrix H = weightsIH.multiply(I)
      .add(biasH)
      .map(ReLU); // Apply activation function

    // Calculate the output layer activations
    Matrix O = weightsHO.multiply(H).add(biasO); // No activation function for output layer
    return O.toArray();
  }

  // For neuroevolution
  NeuralNetwork copy() {
    return new NeuralNetwork(this);
  }

  void mutate(Function<Float, Float> func) {
    this.weightsIH.map(func);
    this.weightsHO.map(func);
    this.biasH.map(func);
    this.biasO.map(func);
  }
}
