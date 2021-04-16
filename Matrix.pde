// https://github.com/CodingTrain/Toy-Neural-Network-JS/blob/master/lib/matrix.js
// https://introcs.cs.princeton.edu/java/95linear/Matrix.java.html

import java.util.function.Function;

class Matrix {
  final int rows;
  final int cols;
  float[][] data;

  Matrix(int rows, int cols) {
    this.rows = rows;
    this.cols = cols;

    this.data = new float[rows][cols];
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.cols; j++) {
        this.data[i][j] = 0;
      }
    }
  }

  Matrix copy() {
    Matrix m = new Matrix(this.rows, this.cols);
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.cols; j++) {
        m.data[i][j] = this.data[i][j];
      }
    }
    return m;
  }

  // Should be static but Processing has a limit on this feature.
  Matrix fromArray(float[] arr) {
    return new Matrix(arr.length, 1).map((e, i, j) -> arr[i]);
  }

  float[] toArray() {
    float[] arr = new float[this.rows*this.cols];
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.cols; j++) {
        arr[i*this.cols + j] = this.data[i][j];
      }
    }

    return arr;
  }

  void randomize() {
    this.selfMap((e) -> (float)(Math.random() * 2 - 1)); // [-1,1)
  }

  Matrix add(Matrix B) {
    if (this.rows != B.rows || this.cols != B.cols) throw new RuntimeException("Invalid matrix dimensions.");

    return this.map((e, i, j) -> e + B.data[i][j]);
  }

  // Slow implementation
  Matrix multiply(Matrix B) {
    if (this.cols != B.rows) throw new RuntimeException("Invalid matrix dimensions.");

    Matrix C = new Matrix(this.rows, B.cols);
    for (int i = 0; i < C.rows; i++) {
      for (int j = 0; j < C.cols; j++) {
        float dotProduct = 0;
        for (int k = 0; k < this.cols; k++) {
          dotProduct += this.data[i][k] * B.data[k][j];
        }
        C.data[i][j] = dotProduct;
      }
    }
    return C;
  }

  Matrix map(TriFunction<Float, Integer, Integer, Float> func) {
    Matrix C = new Matrix(this.rows, this.cols);
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.cols; j++) {
        float val = this.data[i][j];
        C.data[i][j] = func.apply(val, i, j);
      }
    }
    return C;
  }

  Matrix map(Function<Float, Float> func) {
    Matrix C = new Matrix(this.rows, this.cols);
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.cols; j++) {
        float val = this.data[i][j];
        C.data[i][j] = func.apply(val);
      }
    }
    return C;
  }

  void selfMap(Function<Float, Float> func) {
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.cols; j++) {
        float val = this.data[i][j];
        this.data[i][j] = func.apply(val);
      }
    }
  }

  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("[");
    for (int i = 0; i < this.rows; i++) {
      if (i == 0) sb.append("[");
      else sb.append(" [");

      for (int j = 0; j < this.cols; j++) {
        sb.append(this.data[i][j]);
        if (j != this.cols-1) sb.append(", ");
      }

      if (i == this.rows - 1) sb.append("]]\n");
      else sb.append("],\n");
    }
    return sb.toString();
  }
}
