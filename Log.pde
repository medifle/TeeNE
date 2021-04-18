public static class Log {
  private static int INFO = 1;
  private static int DEBUG = 2;

  private static int level = 1; // Change the level of log output

  public static void i(String content) {
    if (level >= INFO) {
      System.out.println(content);
    }
  }

  public static void d(String content) {
    if (level >= DEBUG) {
      System.out.println(content);
    }
  }
}
