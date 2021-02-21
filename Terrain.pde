class Terrain {
  float posY;
  float groundOffset = 1;
  
  float leftBoundary = 4;
  float rightBoundary = width - 4;

  Terrain() {
    posY = 350;
  }

  void render() {
    // The ground
    noStroke();
    fill(230);
    rect(0, posY+groundOffset, width, height-posY);
    
    // The ground line
    stroke(60);
    strokeWeight(1);
    line(0, posY+groundOffset, width, posY+groundOffset);
    stroke(0);
  }
}
