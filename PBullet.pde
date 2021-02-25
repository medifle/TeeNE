class PBullet {
  // TODO: generalize the Bullet type
  Pistol weapon;

  float speed = 12;

  PVector pos;
  PVector vel;
  
  // bullet.pos - enemy.pos
  // This is used by enemy's sensor
  // Stored in this class is to improve perf and simplify code
  // though in theory it is probably enemy's responbility to maintain the info
  PVector enemyDist;
  
  int face;

  boolean isShot = false;

  // For drawing
  PShape bulletRShape, bulletLShape;

  // TODO: Need a Weapon absract class to generalize
  PBullet(Pistol p) {
    weapon = p;
    pos = new PVector();
    vel = new PVector();
    enemyDist = new PVector();

    loadBulletShape();
  }

  void prepare() {
    face = weapon.tee.face;
    pos.set(weapon.tee.pos.x + 65 * face, weapon.tee.pos.y);
    vel.set(speed * face, 0);
    isShot = true;
  }

  // Enemy relative distance
  // x enemy pos.x
  // y enemy pos.y
  void updateEnemyDist(float x, float y) {
    enemyDist.set(pos.x - x, pos.y - y);
  }

  void reset() {
    face = 0;
    pos.set(0, 0);
    vel.set(0, 0);
    enemyDist.set(0, 0);
    isShot = false;
  }

  void move() {
    if (isShot) {
      float newPosX = pos.x + vel.x;
      if (newPosX > terrain.rightBoundary || newPosX < terrain.leftBoundary) {
        reset();
      } else {
        pos.x = newPosX;
      }
    }
  }

  void loadBulletShape() {
    // Bullet facing right
    bulletRShape = createShape(GROUP);
    PShape r0 = createShape(ELLIPSE, 0, 0, 20, 15);
    r0.setFill(color(253, 240, 156));
    r0.setStrokeWeight(1.8);

    PShape r1 = createShape(ELLIPSE, 4, -2, 8, 6);
    r1.setFill(color(255, 248, 198));
    r1.setStrokeWeight(0);

    bulletRShape.addChild(r0);
    bulletRShape.addChild(r1);

    // Bullet facing left
    bulletLShape = createShape(GROUP);
    PShape l0 = createShape(ELLIPSE, 0, 0, 20, 15);
    l0.setFill(color(253, 240, 156));
    l0.setStrokeWeight(1.8);

    PShape l1 = createShape(ELLIPSE, -4, -2, 8, 6);
    l1.setFill(color(255, 248, 198));
    l1.setStrokeWeight(0);

    bulletLShape.addChild(l0);
    bulletLShape.addChild(l1);
  }

  void render() {
    if (isShot) {
      if (face == 1) {
        shape(bulletRShape, pos.x, pos.y);
      } else {
        shape(bulletLShape, pos.x, pos.y);
      }
    }
  }
}
