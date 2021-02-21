class PBullet {
  // TODO: generalize the Bullet type
  Pistol weapon;
  
  float speed = 12;
  
  PVector pos;
  PVector vel;
  int face;
  
  boolean isShot = false;
  
  // For drawing
  PShape bulletRight, bulletLeft;

  // TODO: Need a Weapon absract class to generalize
  PBullet(Pistol p) {
    weapon = p;
    pos = new PVector();
    vel = new PVector();
    
    loadBulletShape();
  }
  
  void prepare() {
    face = weapon.tee.face;
    pos.set(weapon.tee.pos.x + 65 * face, weapon.tee.pos.y);
    vel.set(speed * face, 0);
    isShot = true;
  }
  
  void reset() {
    face = 0;
    pos.set(0,0);
    vel.set(0,0);
    isShot = false;
  }
  
  void move() {
    float newPosX = pos.x + vel.x;
    if (newPosX > terrain.rightBoundary || newPosX < terrain.leftBoundary) {
      reset();
    } else {
      pos.x = newPosX;
    }
  }
  
  void loadBulletShape() {
    // Bullet facing right
    bulletRight = createShape(GROUP);
    PShape r0 = createShape(ELLIPSE, 0, 0, 20, 15);
    r0.setFill(color(253,240,156));
    r0.setStrokeWeight(1.8);
    
    PShape r1 = createShape(ELLIPSE, 4, -2, 8, 6);
    r1.setFill(color(255,248,198));
    r1.setStrokeWeight(0);
    
    bulletRight.addChild(r0);
    bulletRight.addChild(r1);
    
    // Bullet facing left
    bulletLeft = createShape(GROUP);
    PShape l0 = createShape(ELLIPSE, 0, 0, 20, 15);
    l0.setFill(color(253,240,156));
    l0.setStrokeWeight(1.8);
    
    PShape l1 = createShape(ELLIPSE, -4, -2, 8, 6);
    l1.setFill(color(255,248,198));
    l1.setStrokeWeight(0);
    
    bulletLeft.addChild(l0);
    bulletLeft.addChild(l1);
  }
  
  void render() {
    if (isShot) {
      if (face == 1) {
        shape(bulletRight, pos.x, pos.y);
      } else {
        shape(bulletLeft, pos.x, pos.y);
      }
    }
  }
}
