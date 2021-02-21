import java.util.*;

class Pistol {
  Tee tee;

  int capacity = 2; // ammu capacity

  // {0, 1}
  // 1 means ability to shoot, 0 otherwise
  // if within injury cool time, it is 0
  int shootable = 1;

  ArrayDeque<PBullet> ammu = new ArrayDeque<>();
  ArrayDeque<PBullet> ammuInAir = new ArrayDeque<>();

  // For drawing
  PShape pistol;

  Pistol(Tee t) {
    tee = t;
    initAmmu();

    loadWeaponShape();
  }

  void initAmmu() {
    for (int i = 0; i < capacity; i++) {
      ammu.add(new PBullet(this));
    }
  }
  
  boolean shootReady() {
    return tee.pressShoot && shootable == 1;
  }

  void shoot() {
    if (!ammu.isEmpty() && !tee.prevPressShoot) { // TODO: and no injury
      shootable = 1;
    } else {
      shootable = 0;
    }
    
    if (shootReady()) {
      PBullet bullet = ammu.pollFirst();
      bullet.prepare();
      ammuInAir.add(bullet);
    }
    tee.prevPressShoot = tee.pressShoot;
  }

  void bulletsMove() {
    for (Iterator<PBullet> iterator = ammuInAir.iterator(); iterator.hasNext(); ) {
      PBullet b = iterator.next();
      b.move();
      if (!b.isShot) {
        iterator.remove();
        ammu.add(b);
      }
    }
  }

  void loadWeaponShape() {
    // Todo: use svg
    pistol = createShape(GROUP);

    PShape p0 = createShape();
    p0.beginShape();
    p0.fill(85);
    p0.strokeWeight(1.5);
    p0.vertex(0, -1);
    p0.vertex(16, -1);
    p0.vertex(17, 1);
    p0.vertex(38, 1);
    p0.vertex(35, 9);
    p0.vertex(28, 9);
    p0.vertex(0, 9);
    p0.endShape(CLOSE);

    PShape p1 = createShape();
    p1.beginShape();
    p1.fill(217);
    p1.strokeWeight(1.5);
    p1.vertex(0, 1);
    p1.vertex(24, 1);
    p1.vertex(23, 4);
    p1.vertex(26, 4);
    p1.vertex(28, 0);
    p1.vertex(33, 0);
    p1.vertex(27, 15);
    p1.vertex(0, 15);
    p1.endShape(CLOSE);

    PShape p2 = createShape();
    p2.beginShape();
    p2.fill(192);
    p2.noStroke();
    p2.fill(192);
    p2.vertex(0, 9);
    p2.vertex(28, 9);
    p2.vertex(26, 14);
    p2.vertex(0, 14);
    p2.endShape(CLOSE);

    pistol.addChild(p0);
    pistol.addChild(p1);
    pistol.addChild(p2);
  }

  void renderWeapon(float x, float y) {
    if (tee.face == -1) { // flip the weapon
      pushMatrix();
      scale(-1, 1);
      shape(pistol, tee.face * x + 23, y-5);
      popMatrix();
    } else {
      shape(pistol, x+23, y-5);
    }
  }

  void renderBullets() {
    for (PBullet b : ammuInAir) {
      b.render();
    }
  }

  void render(float x, float y) {
    renderWeapon(x, y);
    renderBullets();
  }
}
