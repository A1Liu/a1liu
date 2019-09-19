package test;

import runner.LoopRunner;

public class TestRunner extends LoopRunner {

  public static void main(String... args) { launch(); }

  @Override
  public void atStart() throws Exception {}

  @Override
  public void loop() throws Exception {
    quit();
  }

  @Override
  public void atEnd() throws Exception {}
}
