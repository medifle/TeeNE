public class TableUtil {
  Table table;
  String tablePrefix = "gen";
  String genHeader = "gen";

  Tournament tour;

  int populationSize = 200;
  int numOfParams = 270;

  TableUtil(Tournament tour) {
    this.tour = tour;
  }

  void loadData() {
    // https://forum.processing.org/two/discussion/comment/4114/#Comment_4114
    selectInput("Select a file to process:", "fileSelected", null, this);
  }

  void fileSelected(File selection) {
    if (selection == null) {
      println("Window was closed or the user hit cancel.");
    } else {
      loadPath(selection.getAbsolutePath());
    }
  }

  void loadPath(String path) {
    table = loadTable(path, "header");

    // Load gen header
    tour.generation = readGen();

    // Load brain names
    String[] brainNames = new String[populationSize];
    for (int i = 1; i < table.getColumnCount(); i++) {
      brainNames[i-1] = table.getRow(0).getColumnTitle(i);
    }

    for (int i = 0; i < brainNames.length; i++) {
      String brainName = brainNames[i];
      float[] chromosome = readNN(brainName);

      Brain brain = new Brain();
      brain.setName(brainName);
      brain.getNN().fromArray(chromosome);
      tour.population.add(brain);
    }
  }

  void saveData() {
    if (tour.population.isEmpty()) throw new RuntimeException("population empty.");

    table = new Table();

    makeRows(numOfParams);
    writeGen(genHeader, tour.generation);

    for (int i = 0; i < tour.population.size(); i++) {
      Brain brain = tour.population.get(i);
      String brainName = brain.getName();
      float[] chromosome = brain.getNN().toArray();

      writeNN(brainName, chromosome);
    }

    // Save to disk
    saveTable(table, "data/"+tablePrefix + tour.generation+".csv");
  }

  void makeRows(int num) {
    for (int i = 0; i< num; i++) {
      table.addRow();
    }
  }

  void writeGen(String name, int num) {
    table.addColumn(name);
    table.setInt(0, name, num);
  }

  int readGen() {
    return table.getInt(0, genHeader);
  }

  void writeNN(String name, float[] array) {
    table.addColumn(name, Table.FLOAT);
    for (int i = 0; i< array.length; i++) {
      table.setFloat(i, name, array[i]);
    }
  }

  float[] readNN(String name) {
    float[] chromosome = new float[numOfParams];
    for (int i = 0; i< chromosome.length; i++) {
      chromosome[i] = table.getFloat(i, name);
    }

    return chromosome;
  }
}
